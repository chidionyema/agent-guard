test:
	bash tests/test_agent_reap.sh
	python3 bin/launchd-lint --selftest
	bash -n bin/load-probe && echo "load-probe: syntax ok"
.PHONY: test
