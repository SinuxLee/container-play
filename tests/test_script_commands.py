import json
import os
import pathlib
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ScriptCommandTests(unittest.TestCase):
    def test_docker_directories_do_not_contain_compose_launchers(self):
        for script in ROOT.glob("*/docker/*.sh"):
            with self.subTest(script=script):
                self.assertNotIn("docker compose", script.read_text())

    def test_mysql_cluster_scripts_select_compose_topologies(self):
        cases = [
            ("mysql/compose/master_slave_v8.sh", "docker-compose-replication.yaml", False),
            ("mysql/compose/proxy_cluster_v8.sh", "docker-compose-replication.yaml", True),
            ("mysql/compose/master_master_v8.sh", "docker-compose-dual.yaml", False),
            ("mysql/compose/group_replication_v8.sh", "docker-compose-group.yaml", False),
        ]
        for script, filename, proxy in cases:
            with self.subTest(script=script):
                calls, docker_envs = self.run_with_mock_docker(script)
                self.assertEqual(len(calls), 1)
                self.assertEqual(
                    pathlib.Path(calls[0][calls[0].index("-f") + 1]).resolve(),
                    ROOT / "mysql/compose" / filename,
                )
                self.assertEqual("--profile" in calls[0], proxy)
                self.assertEqual(calls[0][-2:], ["up", "-d"])
                self.assertEqual(docker_envs[0]["MYSQL_ROOT_PASSWORD"], "Admin123")

    def test_mysql_group_restart_bootstraps_member_with_all_gtids(self):
        with tempfile.TemporaryDirectory() as directory:
            work = pathlib.Path(directory)
            state_file = work / "mysql-state.json"
            state_file.write_text(json.dumps({"online": [], "calls": []}))
            mysql = work / "mysql"
            mysql.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, pathlib, re, sys\n"
                "args = sys.argv[1:]\n"
                "host = args[args.index('-h') + 1]\n"
                "query = next((args[args.index(flag) + 1] for flag in ('-Nse', '-e') "
                "if flag in args), None)\n"
                "if query is None: query = sys.stdin.read()\n"
                "path = pathlib.Path(os.environ['MOCK_MYSQL_STATE'])\n"
                "state = json.loads(path.read_text())\n"
                "state['calls'].append([host, query])\n"
                "if 'GTID_SUBSET' in query:\n"
                "    sets = re.search(r\"GTID_SUBSET\\('([^']*)','([^']*)'\\)\", query).groups()\n"
                "    def latest(value): return int(value.split('-')[-1]) if value else 0\n"
                "    print(int(latest(sets[0]) <= latest(sets[1])))\n"
                "elif '@@GLOBAL.gtid_executed' in query:\n"
                "    print({'mysql-gr1': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa:1-2', "
                "'mysql-gr2': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa:1-3', "
                "'mysql-gr3': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa:1-3'}[host])\n"
                "elif 'MEMBER_STATE' in query and 'MEMBER_ID' in query:\n"
                "    print(int(host in state['online']))\n"
                "elif 'MEMBER_STATE' in query:\n"
                "    print(len(state['online']))\n"
                "if 'START GROUP_REPLICATION' in query and host not in state['online']:\n"
                "    state['online'].append(host)\n"
                "path.write_text(json.dumps(state))\n"
            )
            mysql.chmod(0o755)
            env = os.environ.copy()
            env.update({
                "PATH": f"{work}:{env['PATH']}",
                "MOCK_MYSQL_STATE": str(state_file),
                "MYSQL_ROOT_PASSWORD": "Admin123",
                "MYSQL_REPLICATION_PASSWORD": "Admin123",
            })
            result = subprocess.run(
                ["bash", str(ROOT / "mysql/compose/init-group.sh")],
                env=env, capture_output=True, text=True, timeout=15,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            calls = json.loads(state_file.read_text())["calls"]
            bootstrap_hosts = [host for host, query in calls if "group_replication_bootstrap_group=ON" in query]
            self.assertEqual(bootstrap_hosts, ["mysql-gr2"])
            started = [host for host, query in calls if "START GROUP_REPLICATION" in query]
            self.assertEqual(started, ["mysql-gr2", "mysql-gr1", "mysql-gr3"])

    def run_with_mock_docker(self, script, extra_env=None, repeat=1, args=()):
        with tempfile.TemporaryDirectory() as directory:
            work = pathlib.Path(directory)
            docker = work / "docker"
            calls_file = work / "docker-calls.jsonl"
            env_file = work / "docker-env.jsonl"
            docker.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "args = sys.argv[1:]\n"
                "if args[:2] == ['inspect', '--format'] and args[-1] == 'mysql' "
                "and os.environ.get('MOCK_DOCKER_MYSQL_RUNNING') == '1':\n"
                "    print('true')\n"
                "for index, arg in enumerate(args[:-1]):\n"
                "    if arg in ('-e', '--env') and '=' not in args[index + 1]:\n"
                "        if args[index + 1] not in os.environ:\n"
                "            sys.exit('missing forwarded environment variable: ' + args[index + 1])\n"
                "with open(os.environ['DOCKER_CALLS'], 'a') as output:\n"
                "    output.write(json.dumps(args) + '\\n')\n"
                "with open(os.environ['DOCKER_ENVS'], 'a') as output:\n"
                "    output.write(json.dumps({key: value for key, value in os.environ.items() "
                "if key in os.environ['TRACKED_ENVS'].split(',')}) + '\\n')\n"
            )
            docker.chmod(0o755)
            env = os.environ.copy()
            tracked = (
                "MYSQL_ROOT_PASSWORD", "MONGO_INITDB_ROOT_USERNAME", "MONGO_INITDB_ROOT_PASSWORD", "MONGODB_HOST_PORT", "POSTGRES_PASSWORD",
                "REDIS_PASSWORD", "NACOS_AUTH_TOKEN", "NACOS_AUTH_IDENTITY_KEY",
                "NACOS_AUTH_IDENTITY_VALUE", "MYSQL_SERVICE_PASSWORD", "YAPI_ADMIN_PASSWORD",
                "YAPI_DB_PASS", "YAPI_ADMIN_ACCOUNT", "YAPI_DB_USER",
                "ME_CONFIG_BASICAUTH_USERNAME", "ME_CONFIG_BASICAUTH_PASSWORD",
                "ME_CONFIG_MONGODB_SERVER", "ME_CONFIG_MONGODB_ADMINUSERNAME",
                "ME_CONFIG_MONGODB_ADMINPASSWORD", "CONSUL_LOCAL_CONFIG",
                "PARSE_APP_ID", "PARSE_MASTER_KEY", "PARSE_DATABASE_URI", "PARSE_LINK_MONGO",
                "GRAFANA_ADMIN_PASSWORD", "APOLLO_DB_PASSWORD", "PIKA_PASSWORD", "ALERT_WEBHOOK_URL",
                "HOST_BIND_ADDRESS", "MONITORING_NETWORK", "PMA_HOST", "KAFKA_EXTERNAL_HOST",
                "KAFKA_NETWORK",
                "CLOUDBEAVER_LINK_MYSQL", "MOCK_DOCKER_MYSQL_RUNNING",
            )
            for key in tracked:
                env.pop(key, None)
            env.update(extra_env or {})
            env["PATH"] = f"{work}:{env['PATH']}"
            env["DOCKER_CALLS"] = str(calls_file)
            env["DOCKER_ENVS"] = str(env_file)
            env["TRACKED_ENVS"] = ",".join(tracked)
            for _ in range(repeat):
                result = subprocess.run(
                    ["bash", str(ROOT / script), *args], cwd=work, env=env, text=True,
                    capture_output=True, timeout=10,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
            calls = [json.loads(line) for line in calls_file.read_text().splitlines()]
            docker_envs = [json.loads(line) for line in env_file.read_text().splitlines()]
            self.generated_files = {
                str(path.relative_to(work)): path.read_text()
                for path in (
                    work / "prometheus/etc/prometheus.yml",
                    work / "prometheus/etc/alert_rules.yml",
                    work / "alertmanager/alertmanager.yml",
                )
                if path.is_file()
            }
            return calls, docker_envs

    def test_gridstudio_has_one_complete_docker_command(self):
        calls, _ = self.run_with_mock_docker("gridstudio/docker/standalone.sh")
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][-1], "ricklamers/gridstudio:release")
        self.assertIn("127.0.0.1:4430:4430", calls[0])

    def test_parse_starts_server_and_dashboard(self):
        calls, _ = self.run_with_mock_docker(
            "parseplatform/docker/standalone.sh",
            {"PARSE_APP_ID": "demo", "PARSE_MASTER_KEY": "secret", "PARSE_DATABASE_URI": "mongodb://mongo/test"},
        )
        self.assertEqual(len(calls), 2)
        self.assertIn("parseplatform/parse-server:8.5.0", calls[0])
        self.assertIn("parseplatform/parse-dashboard:8.1.0", calls[1])
        self.assertNotIn("mongo:mongo", calls[0])

    def test_kong_mounts_generated_config_and_keeps_admin_listen_together(self):
        calls, _ = self.run_with_mock_docker("kong/docker/standalone.sh")
        args = calls[0]
        self.assertEqual(len(calls), 1)
        self.assertNotIn("ssl", args)
        self.assertIn("KONG_ADMIN_LISTEN=0.0.0.0:8001,0.0.0.0:8444 ssl", args)
        mount = args[args.index("-v") + 1]
        self.assertTrue(mount.endswith("kong.yaml:/usr/local/kong/declarative/kong.yml:ro"))

    def test_svn_does_not_publish_the_same_port_twice(self):
        calls, _ = self.run_with_mock_docker("svn/docker/standalone.sh")
        self.assertEqual(len(calls), 2)
        self.assertIn("127.0.0.1:3690:3690", calls[0])
        self.assertNotIn("127.0.0.1:3690:3690", calls[1])

    def test_scripts_with_local_defaults_run_without_external_variables(self):
        scripts = [
            "mysql/docker/standalone_v57.sh", "mysql/docker/standalone_v8.sh",
            "mysql/docker/standalone_v9.sh", "mongodb/docker/standalone_v4.sh",
            "mongodb/docker/standalone_v7.sh",
            "postgres/docker/standalone.sh", "redis/docker/standalone_v7.sh",
            "redis/docker/standalone_stack_insight.sh", "redis/docker/standalone_stack_server.sh",
            "grafana/docker/standalone.sh", "nacos/docker/standalone-basic.sh",
            "nacos/docker/standalone-mysql.sh", "apollo/docker/standalone.sh",
            "yapi/docker/standalone.sh", "mongo-express/docker/standalone.sh",
            "parseplatform/docker/standalone.sh", "alertmanager/docker/standalone.sh",
            "pika/docker/standalone.sh",
        ]
        for script in scripts:
            with self.subTest(script=script):
                calls, _ = self.run_with_mock_docker(script)
                self.assertTrue(calls)

    def test_defaults_and_explicit_overrides_reach_docker(self):
        for script, variable in [
            ("mysql/docker/standalone_v8.sh", "MYSQL_ROOT_PASSWORD"),
            ("mongodb/docker/standalone_v4.sh", "MONGO_INITDB_ROOT_PASSWORD"),
            ("mongodb/docker/standalone_v7.sh", "MONGO_INITDB_ROOT_PASSWORD"),
            ("postgres/docker/standalone.sh", "POSTGRES_PASSWORD"),
            ("yapi/docker/standalone.sh", "YAPI_ADMIN_PASSWORD"),
            ("yapi/docker/standalone.sh", "YAPI_DB_PASS"),
            ("nacos/docker/standalone-basic.sh", "NACOS_AUTH_IDENTITY_VALUE"),
            ("mongo-express/docker/standalone.sh", "ME_CONFIG_MONGODB_ADMINPASSWORD"),
        ]:
            with self.subTest(script=script):
                _, docker_envs = self.run_with_mock_docker(script)
                self.assertEqual(docker_envs[0][variable], "Admin123")
                _, docker_envs = self.run_with_mock_docker(script, {variable: "custom-secret"})
                self.assertEqual(docker_envs[0][variable], "custom-secret")

    def test_mongodb_7_standalone_has_auth_and_configurable_host_port(self):
        calls, docker_envs = self.run_with_mock_docker("mongodb/docker/standalone_v7.sh")
        self.assertEqual(calls[0][-2:], ["mongo:7.0", "--auth"])
        self.assertIn("127.0.0.1:27017:27017", calls[0])
        self.assertEqual(docker_envs[0]["MONGO_INITDB_ROOT_USERNAME"], "admin")

        calls, _ = self.run_with_mock_docker(
            "mongodb/docker/standalone_v7.sh", {"MONGODB_HOST_PORT": "27018"},
        )
        self.assertIn("127.0.0.1:27018:27017", calls[0])

    def test_redis_8_cluster_scripts_start_the_same_compose_project(self):
        calls, _ = self.run_with_mock_docker("redis/compose/master_slave_v8.sh")
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][:1], ["compose"])
        compose_file = pathlib.Path(calls[0][calls[0].index("-f") + 1]).resolve()
        self.assertEqual(compose_file, ROOT / "redis/compose/docker-compose-v8.yaml")
        self.assertEqual(calls[0][-4:], ["up", "-d", "redis-master", "redis-replica"])

        calls, _ = self.run_with_mock_docker("redis/compose/sentinel_v8.sh")
        self.assertEqual(len(calls), 1)
        self.assertIn("sentinel", calls[0])
        self.assertEqual(calls[0][-2:], ["up", "-d"])

    def test_redis_sentinel_keeps_writable_state_and_quotes_password(self):
        with tempfile.TemporaryDirectory() as directory:
            work = pathlib.Path(directory)
            server = work / "redis-server"
            server.write_text("#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$REDIS_SERVER_ARGS\"\n")
            server.chmod(0o755)
            config = work / "sentinel.conf"
            env = os.environ.copy()
            env.update({
                "PATH": f"{work}:{env['PATH']}",
                "REDIS_PASSWORD": 'space "quote" \\ slash',
                "SENTINEL_CONFIG_PATH": str(config),
                "REDIS_SERVER_ARGS": str(work / "args"),
            })
            script = ROOT / "redis/compose/init-sentinel.sh"
            result = subprocess.run(["sh", str(script)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('sentinel auth-pass mymaster "space \\"quote\\" \\\\ slash"', config.read_text())
            self.assertEqual((work / "args").read_text().splitlines(), [str(config), "--sentinel"])

            config.write_text("sentinel monitor mymaster redis-replica 6379 2\n")
            result = subprocess.run(["sh", str(script)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(config.read_text(), "sentinel monitor mymaster redis-replica 6379 2\n")

    def test_kafka_kraft_starts_broker_and_ui_from_one_compose_file(self):
        calls, _ = self.run_with_mock_docker("kafka/compose/standalone_kraft.sh")
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][0], "compose")
        compose_file = pathlib.Path(calls[0][calls[0].index("-f") + 1]).resolve()
        self.assertEqual(compose_file, ROOT / "kafka/compose/docker-compose-kraft.yaml")
        self.assertEqual(calls[0][-2:], ["up", "-d"])

        env = os.environ.copy()
        env["HOST_BIND_ADDRESS"] = "0.0.0.0"
        env.pop("KAFKA_EXTERNAL_HOST", None)
        result = subprocess.run(
            ["bash", str(ROOT / "kafka/compose/standalone_kraft.sh")],
            env=env, capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("KAFKA_EXTERNAL_HOST", result.stderr)

    def test_compose_launchers_support_common_actions(self):
        scripts = [
            "kafka/compose/standalone_kraft.sh",
            "redis/compose/master_slave_v8.sh", "redis/compose/sentinel_v8.sh",
            "mongodb/compose/replica_set_v4.sh", "mongodb/compose/single_shard_cluster_v4.sh",
            "mongodb/compose/multi_shard_cluster_v4.sh",
            "mysql/compose/master_slave_v8.sh", "mysql/compose/proxy_cluster_v8.sh",
            "mysql/compose/master_master_v8.sh", "mysql/compose/group_replication_v8.sh",
        ]
        for script in scripts:
            with self.subTest(script=script):
                calls, _ = self.run_with_mock_docker(script, args=("down",))
                self.assertEqual(calls[0][-1], "down")
                calls, _ = self.run_with_mock_docker(script, args=("clean",))
                self.assertEqual(calls[0][-2:], ["down", "--volumes"])

        for script, profile in [
            ("redis/compose/master_slave_v8.sh", "sentinel"),
            ("mongodb/compose/single_shard_cluster_v4.sh", "multi"),
            ("mysql/compose/master_slave_v8.sh", "proxy"),
        ]:
            with self.subTest(profile=script):
                calls, _ = self.run_with_mock_docker(script, args=("clean",))
                self.assertEqual(calls[0][calls[0].index("--profile") + 1], profile)

        script = "mysql/compose/master_slave_v8.sh"
        for action, extra, expected in [
            ("ps", (), ["ps"]),
            ("logs", ("-f",), ["logs", "--tail=100", "-f"]),
            ("config", ("--quiet",), ["config", "--quiet"]),
            ("up", (), ["up", "-d"]),
        ]:
            with self.subTest(action=action):
                calls, _ = self.run_with_mock_docker(script, args=(action, *extra))
                self.assertEqual(calls[0][-len(expected):], expected)

        help_result = subprocess.run(
            ["bash", str(ROOT / script), "--help"], capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(help_result.returncode, 0)
        self.assertIn("clean", help_result.stdout)
        self.assertIn("数据卷", help_result.stdout)
        invalid_result = subprocess.run(
            ["bash", str(ROOT / script), "invalid"], capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(invalid_result.returncode, 2)

    def test_mongodb_4_cluster_scripts_select_expected_compose_project(self):
        cases = [
            ("mongodb/compose/replica_set_v4.sh", "docker-compose-v4-replica-set.yaml", False),
            ("mongodb/compose/single_shard_cluster_v4.sh", "docker-compose-v4-sharded.yaml", False),
            ("mongodb/compose/multi_shard_cluster_v4.sh", "docker-compose-v4-sharded.yaml", True),
        ]
        for script, filename, multi in cases:
            with self.subTest(script=script):
                calls, _ = self.run_with_mock_docker(script)
                self.assertEqual(len(calls), 1)
                self.assertEqual(
                    pathlib.Path(calls[0][calls[0].index("-f") + 1]).resolve(),
                    ROOT / "mongodb/compose" / filename,
                )
                self.assertEqual("--profile" in calls[0], multi)
                self.assertEqual(calls[0][-2:], ["up", "-d"])

    def test_consul_reuses_generated_token(self):
        _, docker_envs = self.run_with_mock_docker("consul/docker/standalone.sh", repeat=2)
        self.assertEqual(docker_envs[0]["CONSUL_LOCAL_CONFIG"], docker_envs[1]["CONSUL_LOCAL_CONFIG"])

    def test_parse_default_links_to_local_mongo(self):
        calls, _ = self.run_with_mock_docker("parseplatform/docker/standalone.sh")
        self.assertIn("mongo:mongo", calls[0])
        self.assertIn("mongodb://admin:Admin123@mongo:27017/test?authSource=admin", calls[0])

    def test_mongo_express_can_link_to_mongodb_7_standalone(self):
        calls, _ = self.run_with_mock_docker(
            "mongo-express/docker/standalone.sh", {"ME_CONFIG_MONGODB_SERVER": "mongo7"},
        )
        self.assertIn("mongo7:mongo7", calls[0])

    def test_monitoring_standalones_share_network_and_internal_names(self):
        for script, port in [
            ("alertmanager/docker/standalone.sh", "9093"),
            ("node-exporter/docker/standalone.sh", "9100"),
            ("prometheus/docker/standalone.sh", "9090"),
            ("grafana/docker/standalone.sh", "3000"),
        ]:
            with self.subTest(script=script):
                calls, _ = self.run_with_mock_docker(script)
                run = next(call for call in calls if call[0] == "run")
                self.assertIn("container-play-monitoring", run)
                self.assertIn(f"127.0.0.1:{port}:{port}", run)
                self.assertNotIn("--net=host", run)
                if script == "grafana/docker/standalone.sh":
                    self.assertTrue(any(
                        argument.endswith("/provisioning:/etc/grafana/provisioning:ro")
                        for argument in run
                    ))

        self.run_with_mock_docker("prometheus/docker/standalone.sh")
        config = self.generated_files["prometheus/etc/prometheus.yml"]
        self.assertIn("alertmanager:9093", config)
        self.assertIn("node-exporter:9100", config)
        self.assertIn("prometheus:9090", config)
        self.assertIn("InstanceDown", self.generated_files["prometheus/etc/alert_rules.yml"])
        self.assertIn(
            "http://prometheus:9090",
            (ROOT / "grafana/provisioning/datasources/prometheus.yml").read_text(),
        )

        self.run_with_mock_docker("alertmanager/docker/standalone.sh")
        self.assertNotIn("webhook_configs", self.generated_files["alertmanager/alertmanager.yml"])
        self.run_with_mock_docker(
            "alertmanager/docker/standalone.sh", {"ALERT_WEBHOOK_URL": "http://receiver:8080/alert"},
        )
        self.assertIn("http://receiver:8080/alert", self.generated_files["alertmanager/alertmanager.yml"])

    def test_host_binding_and_monitoring_network_can_be_overridden(self):
        calls, _ = self.run_with_mock_docker(
            "prometheus/docker/standalone.sh",
            {"HOST_BIND_ADDRESS": "192.0.2.10", "MONITORING_NETWORK": "custom-monitoring"},
        )
        run = next(call for call in calls if call[0] == "run")
        self.assertIn("192.0.2.10:9090:9090", run)
        self.assertIn("custom-monitoring", run)

        calls, _ = self.run_with_mock_docker(
            "mysql/docker/standalone_v8.sh", {"HOST_BIND_ADDRESS": "192.0.2.10"},
        )
        self.assertIn("192.0.2.10:3306:3306", calls[0])

    def test_phpmyadmin_and_kafka_ui_reach_their_backends(self):
        calls, _ = self.run_with_mock_docker("phpmyadmin/docker/standalone.sh")
        self.assertIn("mysql:mysql", calls[0])

        calls, _ = self.run_with_mock_docker("kafka/docker/standalone_v2.sh")
        runs = [call for call in calls if call[0] == "run"]
        self.assertEqual(len(runs), 3)
        self.assertTrue(all("container-play-kafka" in run for run in runs))
        self.assertIn("KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:29092", runs[2])
        self.assertIn("KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://kafka:29092,EXTERNAL://127.0.0.1:9092", runs[1])
        self.assertIn("127.0.0.1:9092:9092", runs[1])
        self.assertNotIn("127.0.0.1:29092:29092", runs[1])
        self.assertFalse(any("KRAFT" in arg or "PROCESS_ROLES" in arg for arg in runs[1]))

        calls, _ = self.run_with_mock_docker(
            "kafka/docker/standalone_v2.sh",
            {"HOST_BIND_ADDRESS": "0.0.0.0", "KAFKA_EXTERNAL_HOST": "192.0.2.10"},
        )
        runs = [call for call in calls if call[0] == "run"]
        self.assertIn("0.0.0.0:9092:9092", runs[1])
        self.assertIn("KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://kafka:29092,EXTERNAL://192.0.2.10:9092", runs[1])

        env = os.environ.copy()
        env["HOST_BIND_ADDRESS"] = "0.0.0.0"
        env.pop("KAFKA_EXTERNAL_HOST", None)
        result = subprocess.run(
            ["bash", str(ROOT / "kafka/docker/standalone_v2.sh")],
            env=env, capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("KAFKA_EXTERNAL_HOST", result.stderr)

    def test_cloudbeaver_links_running_mysql_without_requiring_it(self):
        calls, _ = self.run_with_mock_docker("cloudbeaver/docker/standalone.sh")
        self.assertNotIn("mysql:mysql", calls[-1])
        self.assertNotIn("host", calls[-1])

        calls, _ = self.run_with_mock_docker(
            "cloudbeaver/docker/standalone.sh", {"MOCK_DOCKER_MYSQL_RUNNING": "1"},
        )
        self.assertIn("mysql:mysql", calls[-1])


if __name__ == "__main__":
    unittest.main()
