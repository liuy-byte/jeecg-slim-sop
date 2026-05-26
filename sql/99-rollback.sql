-- 回滚：把 sys_permission 恢复到执行 SOP 之前的状态
-- 前提：00-backup.sql 已成功生成 sys_permission_backup_slim

START TRANSACTION;

TRUNCATE TABLE sys_permission;

INSERT INTO sys_permission
SELECT * FROM sys_permission_backup_slim;

-- 验证两表行数一致再 COMMIT
SELECT
    (SELECT COUNT(*) FROM sys_permission) AS restored_rows,
    (SELECT COUNT(*) FROM sys_permission_backup_slim) AS backup_rows;

-- 确认无误后手动执行：
-- COMMIT;
-- 如需放弃：
-- ROLLBACK;
