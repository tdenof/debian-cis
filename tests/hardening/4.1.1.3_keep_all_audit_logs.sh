# run-shellcheck
test_audit() {
    describe Running on blank host
    register_test retvalshouldbe 0
    dismiss_count_for_test
    # shellcheck disable=2154
    mkdir -p /etc/audit
    touch /etc/audit/auditd.conf
    run blank /opt/debian-cis/bin/hardening/"${script}".sh --audit-all

    describe Correcting situation
    sed -i 's/audit/enabled/' /opt/debian-cis/etc/conf.d/"${script}".cfg
    /opt/debian-cis/bin/hardening/"${script}".sh || true

    describe Checking resolved state
    register_test retvalshouldbe 0
    register_test contain "[ OK ] ^max_log_file_action[[:space:]]*=[[:space:]]*keep_logs is present in /etc/audit/auditd.conf"
    run resolved /opt/debian-cis/bin/hardening/"${script}".sh --audit-all
}