"""Add authenticated rescue photo storage.

Revision ID: 20261026_case_photos
Revises: 2271ada9e59e
"""

import sqlalchemy as sa

from alembic import op

revision = "20261026_case_photos"
down_revision = "2271ada9e59e"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "case_photos",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "case_id",
            sa.String(36),
            sa.ForeignKey("rescue_cases.id", ondelete="CASCADE"),
            unique=True,
            nullable=False,
        ),
        sa.Column("content_type", sa.String(40), nullable=False),
        sa.Column("data", sa.LargeBinary(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade():
    op.drop_table("case_photos")
