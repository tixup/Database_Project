DROP TRIGGER IF EXISTS blocca_turno_lavoratore;
DROP TRIGGER IF EXISTS blocca_orario_stadiodiavanzamento;
DROP TRIGGER IF EXISTS blocca_orario_progettoedilizio;
DROP TRIGGER IF EXISTS controlla_alert1;
DROP TRIGGER IF EXISTS controlla_alert3;
DROP TRIGGER IF EXISTS Tipo_PuntoAccesso;
DROP TRIGGER IF EXISTS Misure_PuntoAccesso;
DROP TRIGGER IF EXISTS Dominio_Muratura;
DROP TRIGGER IF EXISTS Dominio_Soffitto;
DROP TRIGGER IF EXISTS Dominio_Pavimento;
DROP TRIGGER IF EXISTS Valori_Posizionamento;
DROP PROCEDURE IF EXISTS Coefficiente_Rischio;
DROP PROCEDURE IF EXISTS Calcola_CoeffGravita;
DROP TRIGGER IF EXISTS blocca_turniorario_lavoratore;
DROP PROCEDURE IF EXISTS StatoEdificio;

-- L'OraInizio e l'OraFine di un turno di lavoro di un lavoratore devono essere coerenti
DELIMITER $$
CREATE TRIGGER blocca_turno_lavoratore
BEFORE INSERT ON Turno
FOR EACH ROW
BEGIN
	
    IF NEW.OraFine < NEW.OraInizio THEN
		SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Orari non compatibili';
    END IF;

END $$
DELIMITER ;

-- Un lavoratore non può avere turni che si sovrappongono sullo stesso orario

DELIMITER $$

CREATE TRIGGER blocca_turniorario_lavoratore
BEFORE INSERT ON  Turno
FOR EACH ROW 
BEGIN
	
	IF EXISTS (
				SELECT*
                FROM Turno T
                WHERE T.Giorno = NEW.Giorno AND ((NEW.OraInizio BETWEEN T.OraInizio AND T.OraFine)
												 OR (NEW.OraFine BETWEEN T.OraInizio AND T.OraFine))
					  AND T.CodFiscale = NEW.CodFiscale)
				THEN
                
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Orari non compatibili';
	END IF;
END $$
DELIMITER $$

-- StadioDiAvanzamento deve avere  DataInizio precedente a StimaDataFine e DataFine

DELIMITER $$
CREATE TRIGGER blocca_orario_stadiodiavanzamento
BEFORE INSERT ON StadioDiAvanzamento
FOR EACH ROW
BEGIN

	IF NEW.DataInizio > NEW.StimaDataFine OR NEW.DataInizio > NEW.DataFine THEN
                
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Date non compatibili';
	END IF;
    
END $$
DELIMITER ;

-- In ProgettoEdilizio le date devono essere in questo ordine DataPresentazione 
-- > DataApprovazione > DataInizio > StimaDataFine <=> DataFine dal più vecchio al più nuovo

DELIMITER $$

CREATE TRIGGER blocca_orario_progettoedilizio
BEFORE INSERT ON  ProgettoEdilizio
FOR EACH ROW 
BEGIN
	
	IF NEW.DataApprovazione > NEW.DataInizio OR NEW.DataInizio > NEW.StimaDataFine 
	   OR NEW.DataApprovazione > NEW.StimaDataFine OR NEW.DataApprovazione > NEW.DataFine
       OR NEW.DataInizio > NEW.DataFine 
       THEN
       
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Date non compatibili';
	END IF;
END $$
DELIMITER ;

-- Quando inserisco un alert devo controllare che il valore misurato da un sensore superi il valori di soglia (VERSIONE SENSORI A 1 COMPONENTE)

DELIMITER $$

CREATE TRIGGER controlla_alert1
AFTER INSERT ON  DatiRegistrati
FOR EACH ROW 
BEGIN
	IF 'Triassiale' <> (SELECT S.Tipo
					FROM Sensore S
					WHERE S.Codice = NEW.Codice 
					) AND
		NEW.X > (SELECT S.SogliaDiSicurezza
				FROM Sensore S
                WHERE S.Codice = NEW.Codice
                )
       THEN
       
		INSERT INTO Alert (NumeroDatiReg, Codice) VALUES (NEW.Numero, NEW.Codice);
        
	END IF;
END $$
DELIMITER ;

-- Quando inserisco un alert devo controllare che il valore misurato da un sensore superi il valori di soglia (VERSIONE SENSORI A 3 COMPONENT1)

DELIMITER $$

CREATE TRIGGER controlla_alert3
AFTER INSERT ON  DatiRegistrati
FOR EACH ROW 
BEGIN
    IF 'Triassiale' = (SELECT S.Tipo
					FROM Sensore S
					WHERE S.Codice = NEW.Codice 
					) AND (
	   NEW.X > (SELECT S.SogliaDiSicurezza
				FROM Sensore S
                WHERE S.Codice = NEW.Codice 
                )
                OR
		NEW.Y > (SELECT S.SogliaDiSicurezza
				FROM Sensore S
                WHERE S.Codice = NEW.Codice
                )
                OR
		NEW.Z > (SELECT S.SogliaDiSicurezza
				FROM Sensore S
                WHERE S.Codice = NEW.Codice
                ))
	
                
       THEN
       
		INSERT INTO Alert (NumeroDatiReg, Codice) VALUES (NEW.Numero, NEW.Codice);
        
	END IF;
END $$
DELIMITER ;

-- Il dominio Tipo di PuntoAccesso può assumere solo i valori Porta, Finestra, PortaFinestra

DELIMITER $$

CREATE TRIGGER Tipo_PuntoAccesso
BEFORE INSERT ON  PuntoAccesso
FOR EACH ROW 
BEGIN
	
	IF NEW.Tipo <> 'Porta' AND NEW.Tipo <> 'Finestra' AND
       NEW.Tipo <> 'PortaFinestra' 
    
    THEN
       
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Dominio di Tipo non compatibile';
	END IF;
END $$
DELIMITER ;

-- In PuntoAccesso DistanzaX e DistanzaY e relative dimensioni 
-- del punto di accesso non possono superare rispettivamente l'altezza e la lunghezza del muro

DELIMITER $$

CREATE TRIGGER Misure_PuntoAccesso
BEFORE INSERT ON  PuntoAccesso
FOR EACH ROW 
BEGIN
	
	IF NEW.DistanzaX + NEW.Larghezza > (SELECT Lunghezza
										From Muro M
										WHERE M.ID = NEW.ID
										)
	   OR 
       NEW.DistanzaY + NEW.Altezza > (SELECT Altezza
									  FROM Muro M
								      WHERE M.ID = NEW.ID
								      )
    
    THEN
       
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Misure punto di accesso errate';
	END IF;
END $$
DELIMITER ;

-- In Muratura il dominio di Lato è 'Destra' e 'Sinistra' mente per strato i valori possibili sono 1, 2 o 3

DELIMITER $$

CREATE TRIGGER Dominio_Muratura
BEFORE INSERT ON  Muratura
FOR EACH ROW 
BEGIN
	
	IF NEW.Strato <> 1 AND NEW.Strato <> 2 AND NEW.Strato <> 3 AND 
    NEW.Lato <> 'd' AND NEW.Lato <> 's' AND NEW.Lato <> 'n'
    
    THEN
       
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valori per muratura errati';
	END IF;
END $$
DELIMITER ;

-- In Soffitto Strato può assumere i valori 1, 2 o 3

DELIMITER $$

CREATE TRIGGER Dominio_Soffitto
BEFORE INSERT ON  Soffitto
FOR EACH ROW 
BEGIN
	
	IF NEW.Strato <> 0 AND NEW.Strato <> 1 AND NEW.Strato <> 2 AND NEW.Strato <> 3
    
    THEN
       
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valori Soffitto errati';
	END IF;
END $$
DELIMITER ;

DELIMITER $$

-- In Pavimento Disposizione può assumere i valori 'Orizzontale', 'Verticale' o 'Naturale'

DELIMITER $$

CREATE TRIGGER Dominio_Pavimento
BEFORE INSERT ON  Pavimento
FOR EACH ROW 
BEGIN
	
	IF NEW.Disposizione <> 'Orizzontale' AND NEW.Disposizione <> 'Verticale' AND NEW.Disposizione <> 'Naturale'
    
    THEN
       
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valori per muratura errati';
	END IF;
END $$
DELIMITER ;

DELIMITER $$

-- CoordinataX e CoordinataY di Posizionamento in Sensore non possono superare rispettivamente i valori di lunghezza e altezza del muro relativo 

DELIMITER $$

CREATE TRIGGER Valori_Posizionamento
BEFORE INSERT ON Sensore
FOR EACH ROW
BEGIN
	
    IF NEW.CoordinataX > (SELECT M.Lunghezza
						  FROM Muro M 
                          WHERE M.ID = NEW.ID
                          )
                          OR
	   NEW.CoordinataY > (SELECT M.Altezza
						  FROM Muro M
                          WHERE M.ID = NEW.ID
                          )
	THEN
		
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valori di  posizione Sensore errati';
	END IF;
END $$
DELIMITER ;

-- Calcola il coefficiente di gravità associato a un evento calamitoso

DELIMITER $$
CREATE PROCEDURE Calcola_CoeffGravita (IN data1 DATE, IN latitudine1 DECIMAL(9,6), IN longitudine1 DECIMAL(9,6), OUT livelloout FLOAT)
BEGIN

DECLARE livello_gravita FLOAT DEFAULT 1;
DECLARE numero_edifici INT DEFAULT 0;

SET numero_edifici = (SELECT count(*)
					  FROM Edificio E
						   INNER JOIN
                           AreaGeografica A ON E.Latitudine = A.Latitudine AND E.Longitudine = A.Longitudine
                      WHERE E.Latitudine = latitudine1 AND E.Longitudine = longitudine1
                      );

IF numero_edifici > 0 THEN

	SET livello_gravita = (SELECT MAX(sqrt(R.X*R.X+R.Y*R.Y+R.Z+R.Z)-S.SogliaDiSicurezza) as Valore
						   FROM DatiRegistrati R 
								INNER JOIN
                                Sensore S on S.Codice = R.Codice
                                INNER JOIN
                                Formazione F on F.IDmuro = S.ID
                                INNER JOIN 
                                Edificio E ON E.Codice = F.CodEdificio
						   WHERE date(R.Timestamp) = data1 AND E.Latitudine = latitudine1 AND E.Longitudine = longitudine1
							     AND S.Tipo = 'Triassiale'
                           ) + (SELECT MAX(R.X-S.SogliaDiSicurezza) as Valore
								FROM DatiRegistrati R 
								INNER JOIN
                                Sensore S on S.Codice = R.Codice
                                INNER JOIN
                                Formazione F on F.IDmuro = S.ID
                                INNER JOIN 
                                Edificio E ON E.Codice = F.CodEdificio
						   WHERE date(R.Timestamp) = data1 AND E.Latitudine = latitudine1 AND E.Longitudine = longitudine1
							     AND S.Tipo <> 'Triassiale'
                           );
END IF;

SET livelloout = sqrt(livello_gravita*livello_gravita);
IF livelloout IS NULL OR livelloout < 1 THEN SET livelloout = 1; END IF;

END $$
DELIMITER ;


-- Calcola lo stato di un edificio a partire da un codice in input, lo aggiorna nell'apposita tabella e mostra a schermo alcuni lavori da dover fare

DELIMITER $$
CREATE PROCEDURE StatoEdificio(CodEdificio1 CHAR(21))
BEGIN
	
	WITH SensoriEdificio AS(
		SELECT Codice, F.CodEdificio
        FROM Sensore S
			INNER JOIN
            Formazione F ON F.IDmuro = S.ID
        WHERE F.CodEdificio = CodEdificio1
	),
    MisurazioniScelte AS(
		SELECT R.Codice AS Cod, R.Numero, R.Timestamp
        FROM DatiRegistrati R
			INNER JOIN 
             SensoriEdificio S ON S.Codice = R.Codice
    ),
    AlertInteressati AS(
		SELECT YEAR(R.Timestamp) AS Anno, 0+COUNT(*) AS NumAlert
        FROM Alert A
			INNER JOIN
            MisurazioniScelte MS ON A.NumeroDatiReg = MS.Numero
									AND A.Codice = MS.Cod
		GROUP BY YEAR(Timestamp)
    ),
    CalcoloStato AS(
		SELECT IF(A1.NumAlert > ALL(SELECT A2.NumAlert
								    FROM AlertInteressati A2
                                    WHERE A1.Anno<>A2.Anno), 3, IF(A1.NumAlert=0, 1, 2)) as Stato
        FROM AlertInteressati A1
		WHERE A1.Anno=2023
    )
    UPDATE Edificio
    SET Stato = IFNULL((SELECT Stato FROM CalcoloStato), 1)
    WHERE Codice=CodEdificio1;
    
    
    SELECT IF(Stato=3, 'MessaInSicurezza', IF(Stato=2, 'InstallazioneSensori', 'Buona salute')) As Stato
    FROM Edificio
    WHERE Codice=CodEdificio1;
    
END $$
DELIMITER ;