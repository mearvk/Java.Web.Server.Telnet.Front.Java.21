#ifndef A105_AUDITOR_RIGHTS_H
#define A105_AUDITOR_RIGHTS_H

#include <string>
#include <vector>
#include <cstdint>
#include <mutex>

namespace auditor {

class A105AuditorRights {
public:
    enum class NationalSympathy { Neutral, ProUser, ProState, Unknown };

    struct EncryptionLoad {
        std::string algorithm;    // e.g. "AES-256-GCM"
        std::size_t key_size;     // bits
        double entropy_estimate;  // heuristic 0.0..1.0
    };

    A105AuditorRights();

    // National sympathy state influences policy decisions (simulation only).
    void setNationalSympathy(NationalSympathy s);
    NationalSympathy getNationalSympathy() const;

    // Analysis of an encryption load — records a non-actionable assessment.
    void assessEncryptionLoad(const EncryptionLoad& load);

    // Policy-only checks (do NOT perform network or privileged operations).
    bool canModifyRemoteAdmin(const std::string& host) const;

    // Simulated request to close a remote port. Returns whether policy allows the action.
    // This function does NOT perform any network or system calls; it only evaluates rules.
    bool requestClosePort(const std::string& host, uint16_t port);

    // Return textual audit report collected during this object's lifetime.
    std::vector<std::string> auditReport() const;

private:
    NationalSympathy sympathy_;
    bool allow_privileged_port_actions_; // whether privileged-port actions are permitted by policy

    mutable std::vector<std::string> reports_;
    mutable std::mutex mu_;
};

} // namespace auditor

#endif // A105_AUDITOR_RIGHTS_H
