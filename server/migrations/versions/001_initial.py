"""initial

Revision ID: 001
Revises: 
Create Date: 2026-07-02 10:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 创建 documents 表
    op.create_table(
        'documents',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('page_count', sa.Integer(), nullable=False, default=1),
        sa.Column('tags', sa.JSON(), nullable=True, default=list),
        sa.Column('file_path', sa.String(), nullable=False),
        sa.Column('thumbnail_path', sa.String(), nullable=True),
        sa.Column('is_favorite', sa.Boolean(), default=False),
        sa.Column('is_deleted', sa.Boolean(), default=False),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('file_size', sa.Integer(), nullable=True),
        sa.Column('mime_type', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    
    # 创建索引
    op.create_index(op.f('ix_documents_id'), 'documents', ['id'], unique=False)
    op.create_index(op.f('ix_documents_user_id'), 'documents', ['user_id'], unique=False)
    op.create_index(op.f('ix_documents_created_at'), 'documents', ['created_at'], unique=False)
    op.create_index(op.f('ix_documents_is_deleted'), 'documents', ['is_deleted'], unique=False)
    
    # 创建 users 表（可选，用于用户认证）
    op.create_table(
        'users',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False, unique=True),
        sa.Column('username', sa.String(), nullable=True),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_active', sa.Boolean(), default=True),
        sa.PrimaryKeyConstraint('id')
    )
    
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_table('users')
    
    op.drop_index(op.f('ix_documents_is_deleted'), table_name='documents')
    op.drop_index(op.f('ix_documents_created_at'), table_name='documents')
    op.drop_index(op.f('ix_documents_user_id'), table_name='documents')
    op.drop_index(op.f('ix_documents_id'), table_name='documents')
    op.drop_table('documents')
