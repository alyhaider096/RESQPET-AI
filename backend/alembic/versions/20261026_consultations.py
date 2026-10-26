"""Add owner and veterinarian consultations."""

import sqlalchemy as sa

from alembic import op

revision = "20261026_consultations"
down_revision = "20261026_case_photos"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "consultations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "organization_id", sa.String(36), sa.ForeignKey("organizations.id"), nullable=False, index=True
        ),
        sa.Column("owner_id", sa.String(36), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("veterinarian_id", sa.String(36), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("species", sa.String(40), nullable=False),
        sa.Column("animal_name", sa.String(120), nullable=False),
        sa.Column("concern", sa.String(40), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("appointment_at", sa.DateTime(timezone=True)),
        sa.Column("vet_note", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade():
    op.drop_table("consultations")
