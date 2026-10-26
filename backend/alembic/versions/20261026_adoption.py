"""Rescued animal adoption and placement workflow."""

import sqlalchemy as sa
from alembic import op

revision = "20261026_adoption"
down_revision = "20261026_consultations"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "adoption_listings",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("case_id", sa.String(36), sa.ForeignKey("rescue_cases.id"), unique=True, nullable=False),
        sa.Column(
            "organization_id", sa.String(36), sa.ForeignKey("organizations.id"), index=True, nullable=False
        ),
        sa.Column("created_by", sa.String(36), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("animal_name", sa.String(120), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("species", sa.String(40), nullable=False),
        sa.Column("district", sa.String(120), nullable=False),
        sa.Column("case_reference", sa.String(24), nullable=False),
        sa.Column("shelter_name", sa.String(160), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "adoption_applications",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "listing_id", sa.String(36), sa.ForeignKey("adoption_listings.id"), index=True, nullable=False
        ),
        sa.Column("applicant_id", sa.String(36), sa.ForeignKey("users.id"), index=True, nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("review_note", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("listing_id", "applicant_id", name="uq_adoption_applicant"),
    )


def downgrade():
    op.drop_table("adoption_applications")
    op.drop_table("adoption_listings")
