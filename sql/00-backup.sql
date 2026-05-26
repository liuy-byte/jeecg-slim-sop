-- 执行精简前备份 sys_permission 表
-- 出问题时用 99-rollback.sql 恢复

DROP TABLE IF EXISTS sys_permission_backup_slim;
CREATE TABLE sys_permission_backup_slim AS
SELECT * FROM sys_permission;

-- 验证：备份行数应等于原表行数
SELECT
    (SELECT COUNT(*) FROM sys_permission) AS original_rows,
    (SELECT COUNT(*) FROM sys_permission_backup_slim) AS backup_rows;
