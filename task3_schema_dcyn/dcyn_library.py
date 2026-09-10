"""
Task 3 - DCYN (Deconstructed Clean Yes/No) Library
Author: Harshil Parmar | Contact: harshilparmar1907@gmil.com | +91 9824624715

Purpose
-------
Deconstruct an incoming student-onboarding JSON payload into a set of strictly
binary Yes/No answers. Every rule is deterministic: given the same payload it
always returns the same answer, which entirely removes human judgement from the
onboarding decision (Poka-Yoke).

Each rule returns the string "Yes" or "No" only - never Maybe, never null.
"""

from typing import Any, Callable, Dict

# Business thresholds are named constants, never magic numbers buried in logic.
MIN_ELIGIBLE_AGE = 4
MAX_ELIGIBLE_AGE = 18
MIN_SUPPORT_HOURS = 1
MAX_SUPPORT_HOURS = 40


def _yesno(condition: bool) -> str:
    """Collapse any boolean to the strict binary vocabulary."""
    return "Yes" if bool(condition) else "No"


# ---------------------------------------------------------------------------
# Individual, single-responsibility rules. Each maps payload -> "Yes"/"No".
# ---------------------------------------------------------------------------
def rule_age_eligible(payload: Dict[str, Any]) -> str:
    age = payload.get("age")
    return _yesno(isinstance(age, int) and MIN_ELIGIBLE_AGE <= age <= MAX_ELIGIBLE_AGE)


def rule_consent_present(payload: Dict[str, Any]) -> str:
    signature = payload.get("consent_signature")
    return _yesno(isinstance(signature, str) and signature.strip() != "")


def rule_has_support_plan(payload: Dict[str, Any]) -> str:
    return _yesno(payload.get("existing_support_plan") is True)


def rule_guardian_contactable(payload: Dict[str, Any]) -> str:
    email = payload.get("guardian_email", "")
    return _yesno(isinstance(email, str) and "@" in email and "." in email.split("@")[-1])


def rule_hours_within_policy(payload: Dict[str, Any]) -> str:
    hours = payload.get("hours_requested_per_week")
    return _yesno(
        isinstance(hours, int) and MIN_SUPPORT_HOURS <= hours <= MAX_SUPPORT_HOURS
    )


def rule_region_assigned(payload: Dict[str, Any]) -> str:
    group = payload.get("region_owner_group", "")
    return _yesno(isinstance(group, str) and group.startswith("region-"))


# Registry: rule name -> callable. Adding a rule here automatically includes it
# in the deconstruction output, so the library stays declarative.
DCYN_RULES: Dict[str, Callable[[Dict[str, Any]], str]] = {
    "is_age_eligible": rule_age_eligible,
    "is_consent_present": rule_consent_present,
    "has_existing_support_plan": rule_has_support_plan,
    "is_guardian_contactable": rule_guardian_contactable,
    "are_hours_within_policy": rule_hours_within_policy,
    "is_region_assigned": rule_region_assigned,
}


def deconstruct(payload: Dict[str, Any]) -> Dict[str, str]:
    """Return the full Yes/No answer set for a payload."""
    return {name: rule(payload) for name, rule in DCYN_RULES.items()}


def is_auto_approvable(payload: Dict[str, Any]) -> str:
    """
    A record is auto-approvable only when EVERY rule answers Yes.
    Returns strict Yes/No, so the downstream system needs no human tie-breaker.
    """
    answers = deconstruct(payload)
    return _yesno(all(answer == "Yes" for answer in answers.values()))


if __name__ == "__main__":
    import json
    import sys

    with open(sys.argv[1] if len(sys.argv) > 1 else "sample_payload.json") as handle:
        data = json.load(handle)

    result = deconstruct(data)
    result["AUTO_APPROVABLE"] = is_auto_approvable(data)
    print(json.dumps(result, indent=2))
