-- 把"个人中心"提升为一级菜单
-- 来源：https://help.jeecg.com/ui/2dev/mini
-- 必须先于 02-delete-demo-menus.sql 执行，否则个人中心会被一起逻辑删除

UPDATE `sys_permission`
SET `parent_id` = '', menu_type = 0
WHERE `id` = '1438108188378521602';
