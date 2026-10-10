;;; test-gptel-pup.el --- Tests for gptel-pup -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'gptel-pup)

;;; Platform asset naming

(ert-deftest test-gptel-pup/platform-asset-name-darwin-arm64 ()
  (let ((system-type 'darwin)
        (system-configuration "aarch64-apple-darwin23.0.0"))
    (should (equal (gptel-pup--platform-asset-name "1.26.0")
                   "pup_1.26.0_Darwin_arm64.tar.gz"))))

(ert-deftest test-gptel-pup/platform-asset-name-linux-x86-64 ()
  (let ((system-type 'gnu/linux)
        (system-configuration "x86_64-pc-linux-gnu"))
    (should (equal (gptel-pup--platform-asset-name "1.26.0")
                   "pup_1.26.0_Linux_x86_64.tar.gz"))))

(ert-deftest test-gptel-pup/platform-asset-name-unsupported ()
  (let ((system-type 'windows-nt))
    (should-error (gptel-pup--platform-asset-name "1.26.0"))))

;;; Command-line construction

(ert-deftest test-gptel-pup/serve-args-defaults ()
  (let ((gptel-pup-host "127.0.0.1")
        (gptel-pup-port 9099)
        (gptel-pup-agent-id nil)
        (gptel-pup-extra-serve-args nil))
    (should (equal (gptel-pup--serve-args)
                   '("acp" "serve" "--host" "127.0.0.1" "--port" "9099")))))

(ert-deftest test-gptel-pup/serve-args-with-agent-id-and-extra ()
  (let ((gptel-pup-host "0.0.0.0")
        (gptel-pup-port 8080)
        (gptel-pup-agent-id "abc-123")
        (gptel-pup-extra-serve-args '("--verbose")))
    (should (equal (gptel-pup--serve-args)
                   '("acp" "serve" "--host" "0.0.0.0" "--port" "8080"
                     "--agent-id" "abc-123" "--verbose")))))

;;; Environment construction

(ert-deftest test-gptel-pup/environment-adds-dd-site-and-org ()
  (let ((gptel-pup-site "datadoghq.eu")
        (gptel-pup-org "staging-child")
        (process-environment '("PATH=/usr/bin")))
    (let ((env (gptel-pup--environment)))
      (should (member "DD_SITE=datadoghq.eu" env))
      (should (member "DD_ORG=staging-child" env))
      (should (member "PATH=/usr/bin" env)))))

(ert-deftest test-gptel-pup/environment-omits-unset-values ()
  (let ((gptel-pup-site nil)
        (gptel-pup-org nil)
        (process-environment '("PATH=/usr/bin")))
    (should (equal (gptel-pup--environment) '("PATH=/usr/bin")))))

;;; Process state

(ert-deftest test-gptel-pup/running-p-nil-when-unset ()
  (let ((gptel-pup--process nil))
    (should-not (gptel-pup-running-p))))

;;; Backend registration

(ert-deftest test-gptel-pup/register-backend-uses-openai-compatible-endpoint ()
  (let ((gptel-pup-host "127.0.0.1")
        (gptel-pup-port 9099)
        (gptel-pup-models '(datadog-ai)))
    (let ((backend (gptel-pup-register-backend)))
      (should (equal (gptel-backend-url backend) "http://127.0.0.1:9099/chat/completions"))
      (should (equal (gptel-backend-models backend) '(datadog-ai)))
      (should-not (funcall (gptel-backend-header backend) nil)))))

(provide 'test-gptel-pup)
;;; test-gptel-pup.el ends here
