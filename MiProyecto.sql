/*	Proyecto Final del curso "Administración de Bases de Datos" (Proteco)
	Trabajo realizado por: Ricardo Cuevas Mondragón
	Julio 2017 
*/

-------------------------------------------------------------------------------------------------------------
-- IMPORTANTE: Empezaré con la creación de un usuario y sus permisos, este paso se puede omitir si ya existe.
-- Conexión a Oracle como sysdba
sqlplus / as sysdba

-- Creación de usuario
CREATE USER rcm IDENTIFIED BY rcm DEFAULT TABLESPACE users QUOTA 100M ON users;
--Otorgar permisos a usuario
GRANT CREATE SESSION, CREATE TABLE TO rcm;
GRANT CREATE SEQUENCE TO rcm;
GRANT CREATE TRIGGER TO rcm;

-- Conexión con usuario creado
conn rcm/rcm
-------------------------------------------------------------------------------------------------------------

-- Creación de tabla OPERACION_CLIENTE
CREATE TABLE operacion_cliente(
	operacion_id NUMERIC(10,0) NOT NULL PRIMARY KEY,
	nombre_cliente VARCHAR2(50) NOT NULL,
	operacion VARCHAR2(500) NOT NULL,
	monto NUMERIC(9,2) NOT NULL
);

-- Creación de tabla AUDITORIA_OPERACION
CREATE TABLE auditoria_operacion(
	auditoria_id NUMERIC(10,0) NOT NULL PRIMARY KEY,
	detalle VARCHAR2(500) NOT NULL
);

-- Creación de secuencia para AUDITORIA_ID
CREATE SEQUENCE sequence_auditoria START WITH 1 INCREMENT BY 1;

-- Creación del TRIGGER
CREATE OR REPLACE TRIGGER operacion 
AFTER INSERT OR DELETE OR UPDATE ON operacion_cliente FOR EACH ROW 
DECLARE
	user VARCHAR2(30);
BEGIN
	SELECT USERNAME INTO user FROM USER_USERS; -- Obtenemos el usuario actual y lo guardamos en la variable USER

	IF INSERTING THEN
		INSERT INTO auditoria_operacion 
		VALUES(sequence_auditoria.nextval,'El usuario '||user||' realizó una operación de inserción. 
			Los datos que se agregaron se guardaron con operacion_id = '||:new.operacion_id||' ,la operación se realizó en la fecha '||to_char(sysdate)||'.');

	ELSIF DELETING THEN
		INSERT INTO auditoria_operacion 
		VALUES(sequence_auditoria.nextval,'El usuario '||user||' eliminó un registro con los siguientes datos. Operacion id: '
			||:old.operacion_id||', Nombre Cliente: '||:old.nombre_cliente||', Operación: '||:old.operacion||', Monto: '||:old.monto||'.');

	ELSIF UPDATING THEN
		INSERT INTO auditoria_operacion
		VALUES(sequence_auditoria.nextval,'El usuario '||user||' realizó una actualización en la fecha ' ||to_char(sysdate)||'. Valores anteriores: '
			||:old.operacion_id||', '||:old.nombre_cliente||', '||:old.operacion||', '||:old.monto||'. Valores nuevos: '
			||:new.operacion_id||', '||:new.nombre_cliente||', '||:new.operacion||', '||:new.monto||'.');

	END IF;
END;
/


-- Ahora lo probamos --

-- Inserciones
INSERT INTO operacion_cliente VALUES(1,'Maria','Depósito',500);
INSERT INTO operacion_cliente VALUES(2,'Tomás','Retiro de efectivo',1500);
INSERT INTO operacion_cliente VALUES(3,'Julio','Apertura de cuenta',2000);

-- Checamos que se haya actualizado la tabla AUDITORIA_OPERACION
SELECT * FROM auditoria_operacion;

-- Eliminamos un registro
DELETE FROM operacion_cliente WHERE nombre_cliente='Julio';

-- Checamos que se haya actualizado la tabla AUDITORIA_OPERACION
SELECT * FROM auditoria_operacion;

-- Actualizamos un registro
UPDATE operacion_cliente SET operacion='Depósito' WHERE operacion_id=2;

-- Checamos que se haya actualizado la tabla AUDITORIA_OPERACION
SELECT * FROM auditoria_operacion;

commit;