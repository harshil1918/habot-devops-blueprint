"""
Task 3 - Django ORM model backing the onboarding record.
Author: Harshil Parmar | Contact: harshilparmar1907@gmil.com | +91 9824624715

Database-level constraints mirror the serializer limits so the rule is enforced
twice: once at the API boundary and once at the storage boundary (defence in
depth). The column set matches the BigQuery D1 schema to prevent drift.
"""

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class StudentOnboarding(models.Model):
    student_id = models.CharField(max_length=15, unique=True)
    full_name = models.CharField(max_length=120)
    age = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(4), MaxValueValidator(18)]
    )
    guardian_email = models.EmailField(max_length=254)
    guardian_phone = models.CharField(max_length=16)
    learning_difficulty_type = models.CharField(max_length=32)
    existing_support_plan = models.BooleanField(default=False)
    hours_requested_per_week = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(40)]
    )
    consent_signature = models.CharField(max_length=120)
    region_owner_group = models.CharField(max_length=27, db_index=True)
    ingested_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "student_onboarding"
        constraints = [
            models.CheckConstraint(
                check=models.Q(age__gte=4) & models.Q(age__lte=18),
                name="age_within_policy",
            ),
            models.CheckConstraint(
                check=models.Q(hours_requested_per_week__gte=1)
                & models.Q(hours_requested_per_week__lte=40),
                name="hours_within_policy",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.student_id} - {self.full_name}"
