"""
Task 3 - Django REST Framework serializer with exact field validation limits.
Author: Harshil Parmar | Contact: harshilparmar1907@gmil.com | +91 9824624715

The serializer is the enforcement boundary. A payload that violates ANY limit
is rejected with a specific error before it can reach the database or the
BigQuery streaming sink. This eliminates the schema mismatch that broke
downstream analytics in the reported incident.
"""

from rest_framework import serializers

from dcyn_library import deconstruct, is_auto_approvable

LEARNING_DIFFICULTY_CHOICES = (
    ("dyslexia", "Dyslexia"),
    ("dyscalculia", "Dyscalculia"),
    ("adhd", "Attention Deficit Hyperactivity Disorder"),
    ("asd", "Autism Spectrum Disorder"),
    ("other", "Other"),
)


class StudentOnboardingSerializer(serializers.Serializer):
    """Validates the raw onboarding payload against exact, documented limits."""

    student_id = serializers.RegexField(
        regex=r"^STU-\d{4}-\d{5}$",
        help_text="Format STU-YYYY-NNNNN, for example STU-2026-00417.",
    )
    full_name = serializers.CharField(min_length=2, max_length=120)
    age = serializers.IntegerField(min_value=4, max_value=18)
    guardian_email = serializers.EmailField(max_length=254)
    guardian_phone = serializers.RegexField(
        regex=r"^\+\d{7,15}$",
        help_text="E.164 format, leading plus and 7 to 15 digits.",
    )
    learning_difficulty_type = serializers.ChoiceField(
        choices=LEARNING_DIFFICULTY_CHOICES
    )
    existing_support_plan = serializers.BooleanField()
    hours_requested_per_week = serializers.IntegerField(min_value=1, max_value=40)
    consent_signature = serializers.CharField(min_length=2, max_length=120)
    region_owner_group = serializers.RegexField(regex=r"^region-[a-z]{2,20}$")

    def validate(self, attrs):
        """Cross-field rule: consent must exist before any record is accepted."""
        if not attrs.get("consent_signature", "").strip():
            raise serializers.ValidationError(
                {"consent_signature": "Guardian consent signature is mandatory."}
            )
        return attrs

    def to_representation(self, instance):
        """Attach the deterministic DCYN Yes/No answer set to the output."""
        data = super().to_representation(instance)
        data["dcyn"] = deconstruct(data)
        data["auto_approvable"] = is_auto_approvable(data)
        return data
