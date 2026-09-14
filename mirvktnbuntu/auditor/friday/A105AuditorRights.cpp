#include "A105AuditorRights.h"
#include <sstream>
#include <iomanip>
#include <iostream>

using namespace auditor;

A105AuditorRights::A105AuditorRights()
    : sympathy_(NationalSympathy::Neutral), allow_privileged_port_actions_(false) {}

void A105AuditorRights::setNationalSympathy(NationalSympathy s) {
    std::lock_guard<std::mutex> lk(mu_);
    sympathy_ = s;
    std::ostringstream ss;
    ss << "Set national sympathy to ";
    switch (s) {
        case NationalSympathy::Neutral: ss << "Neutral"; break;
        case NationalSympathy::ProUser: ss << "ProUser"; break;
        case NationalSympathy::ProState: ss << "ProState"; break;
        default: ss << "Unknown"; break;
    }
    reports_.push_back(ss.str());
}

A105AuditorRights::NationalSympathy A105AuditorRights::getNationalSympathy() const {
    std::lock_guard<std::mutex> lk(mu_);
    return sympathy_;
}

void A105AuditorRights::assessEncryptionLoad(const EncryptionLoad& load) {
    std::ostringstream ss;
    ss << "Encryption assessment: alg=" << load.algorithm
       << " key_bits=" << load.key_size
       << " entropy=" << std::fixed << std::setprecision(2) << load.entropy_estimate;

    // Simple heuristic examples (simulation only)
    if (load.key_size >= 256 && load.entropy_estimate > 0.7) {
        ss << " (strong)";
    } else if (load.key_size >= 128) {
        ss << " (acceptable)";
    } else {
        ss << " (weak)";
    }

    std::lock_guard<std::mutex> lk(mu_);
    reports_.push_back(ss.str());
}

bool A105AuditorRights::canModifyRemoteAdmin(const std::string& host) const {
    std::lock_guard<std::mutex> lk(mu_);
    // Policy simulation: if sympathy is ProState, treat remote-admin as restricted;
    // if ProUser, allow limited changes; Neutral defers to allow_privileged_port_actions_.
    if (sympathy_ == NationalSympathy::ProState) return false;
    if (sympathy_ == NationalSympathy::ProUser) return true;
    return allow_privileged_port_actions_;
}

bool A105AuditorRights::requestClosePort(const std::string& host, uint16_t port) {
    // DO NOT perform any network/system action here. Only simulate policy decision.
    std::ostringstream ss;
    ss << "Request close port: host=" << host << " port=" << port;

    bool allowed = true;
    if (port < 1024) {
        // privileged ports require explicit policy allowance
        allowed = allow_privileged_port_actions_;
    }

    // national sympathy can tighten policy
    {
        std::lock_guard<std::mutex> lk(mu_);
        if (sympathy_ == NationalSympathy::ProState) allowed = false;
        if (!allowed) ss << " -> DENIED by policy";
        else ss << " -> ALLOWED (simulated)";
        reports_.push_back(ss.str());
    }

    return allowed;
}

std::vector<std::string> A105AuditorRights::auditReport() const {
    std::lock_guard<std::mutex> lk(mu_);
    return reports_;
}

// NOTE: This class intentionally never performs destructive or network operations.
// It exists to model policy decisions and produce textual audit reports for testing
// and review purposes only.
