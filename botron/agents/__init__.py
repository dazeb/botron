from botron.agents.analyst import create_analyst_agent
from botron.agents.botron import create_decepticon_agent
from botron.agents.defender import create_defender_agent
from botron.agents.detector import create_detector_agent
from botron.agents.exploit import create_exploit_agent
from botron.agents.exploiter import create_exploiter_agent
from botron.agents.patcher import create_patcher_agent
from botron.agents.postexploit import create_postexploit_agent
from botron.agents.recon import create_recon_agent
from botron.agents.scanner import create_scanner_agent
from botron.agents.soundwave import create_soundwave_agent
from botron.agents.verifier import create_verifier_agent
from botron.agents.vulnresearch import create_vulnresearch_agent

__all__ = [
    "create_recon_agent",
    "create_defender_agent",
    "create_soundwave_agent",
    "create_analyst_agent",
    "create_exploit_agent",
    "create_postexploit_agent",
    "create_decepticon_agent",
    # Vulnresearch pipeline (five-stage modular)
    "create_scanner_agent",
    "create_detector_agent",
    "create_verifier_agent",
    "create_patcher_agent",
    "create_exploiter_agent",
    "create_vulnresearch_agent",
]
