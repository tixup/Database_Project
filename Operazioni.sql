DROP PROCEDURE IF EXISTS Informazioni_Vano;
DROP PROCEDURE IF EXISTS Costo_Lavori;
DROP PROCEDURE IF EXISTS Inserimento_Turno;
DROP PROCEDURE IF EXISTS Edifici_C_R;
DROP PROCEDURE IF EXISTS OperaiAlLavoro;
DROP PROCEDURE IF EXISTS AltezzaMassimaEdificio;
DROP PROCEDURE IF EXISTS NormaVani;
DROP PROCEDURE IF EXISTS INsensore;

-- Informazioni_Vano
-- INPUT: CodEdificio e ID del Vano
-- OUTPUT: Informazioni relative al Vano

DELIMITER $$
CREATE PROCEDURE Informazioni_Vano (IN CodEdificio1 CHAR(21), IN ID1 CHAR(21))
BEGIN

	WITH MuriVano AS (
		SELECT F.IDvano, F.IDmuro, M.Lunghezza, M.Altezza, M.X_0, M.Y_0
        FROM Formazione F
			INNER JOIN
             Muro M ON F.IDmuro = M.ID
        WHERE F.CodEdificio = CodEdificio1 AND F.IDvano = ID1
	),
    PuntiAc AS (
		SELECT M.IDmuro, P.Tipo AS Tipologia, P.DistanzaX, P.DistanzaY
        FROM MuriVano M
			LEFT OUTER JOIN
             PuntoAccesso P ON M.IDmuro = P.ID
	),
    VanoInfo AS (
		SELECT m.IDmuro, m.Lunghezza, m.Altezza, m.X_0, m.Y_0, p.DistanzaX, p.DistanzaY, p.Tipologia
        FROM 
             MuriVano m 
			LEFT OUTER JOIN
			 PuntiAc p ON m.IDmuro = p.IDmuro
    )
    SELECT *
    FROM VanoInfo;
    
END $$
DELIMITER ;

-- Costo lavori di un edificio
-- INPUT CodEdificio
-- OUTPUT Costo complessivo dei lavori

DELIMITER $$
CREATE PROCEDURE Costo_Lavori (IN CodEdificio1 CHAR(21))
BEGIN
	WITH ProgettiEdilizi AS (
		SELECT P.Codice, P.CostoLavori
        FROM ProgettoEdilizio P
        WHERE P.CodEdificio = CodEdificio1
	)
    SELECT SUM(p.CostoLavori)
    FROM ProgettiEdilizi p;
    
END $$
DELIMITER ;

-- Inserimento turno
-- INPUT CodFiscale, stadio di avanzamento, giorno, inizio turno, fine turno, elenco lavori
-- OUTPUT nessuno se l'inserimento ha successo altrimenti restituisce un errore

DELIMITER $$
CREATE PROCEDURE Inserimento_turno (IN ID1 CHAR(21), IN CodFiscale1 CHAR(21), IN ProgettoEdilizio1 CHAR(21), IN Numero1 INT, IN MaxLavoratori1 INT,
									IN Giorno1 DATE, IN OraInizio1 TIME, OraFine1 TIME, IN Lavori1 VARCHAR(500))
BEGIN

IF ((
	WITH LavoratoriStadioDiAvanzamento AS (
		SELECT T2.CodFiscale, T2.MaxLavoratori, T2.OraInizio, T2.OraFine
        FROM Turnazione T1
			INNER JOIN
			 Turno T2 ON T1.ID = T2.ID
        WHERE T1.ProgettoEdilizio = ProgettoEdilizio1 AND T1.Numero = Numero1
			AND T2.Giorno = Giorno1 AND T2.OraInizio = OraInizio1 AND T2.OraFine = OraFine1
	),
    CapicantiereStadioDiAvanzamento AS (
		SELECT L.CodFiscale, L.MaxLavoratori, L.OraInizio, L.OraFine
        FROM LavoratoriStadioDiAvanzamento L
        WHERE L.MaxLavoratori > 0
	),
    NumeroLavoratori AS (
		SELECT COUNT(*) AS n
        FROM LavoratoriStadioDiAvanzamento L
        WHERE L.CodFiscale NOT IN (SELECT CodFiscale
								   FROM CapicantiereStadioDiAvanzamento)
	),
    NumeroLavPossibili AS (SELECT SUM(MaxLavoratori) AS Pos
						   FROM CapicantiereStadioDiAvanzamento
	)
    SELECT 1
    FROM NumeroLavoratori N
		NATURAL JOIN
		 NumeroLavPossibili P
    WHERE N.n < P.Pos
    ) IS NULL
    AND
    MaxLavoratori1 = 0)
    
    THEN
    
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Impossibile inserire: il massimo dei lavoratori è stato raggiunto';
	
    ELSE
		INSERT INTO Turno (ID, Lavori, MaxLavoratori, OraFine, OraInizio, CodFiscale, Giorno) VALUES (ID1, Lavori1, MaxLavoratori1, OraFine1, OraInizio1, CodFiscale1, Giorno1);
        insert into Turnazione (ID, ProgettoEdilizio, Numero) values (ID1, ProgettoEdilizio1, Numero1);
        
    END IF;
    
END $$
DELIMITER ;

-- Edifici in costruzione, ristrutturazione o completati
-- INPUT Data rispetto a cui calcolare lo stato
-- OUTPUT Edifici in costruzione o ristrutturazione o completati

DELIMITER $$
CREATE PROCEDURE Edifici_C_R (IN Giorno1 DATE)
BEGIN
	
    WITH ProgettiInCorso AS (SELECT P.CodEdificio AS EdificioInCostruzione, P.Codice AS Codice1
							FROM ProgettoEdilizio P
							WHERE P.DataFine >= Giorno1 OR P.DataFine IS NULL
	), ProgettiConclusi AS (SELECT P.CodEdificio AS EdificioConcluso, P.Codice
							FROM ProgettoEdilizio P
                            WHERE P.DataFine < Giorno1
	)
    SELECT DISTINCT P1.Codice1 AS CodiceProgettoEdilizioInCorso ,EdificioInCostruzione, P2.Codice AS CodiceProgettoEdilizioConcluso, EdificioConcluso
    FROM ProgettiInCorso P1
		INNER JOIN 
        ProgettiConclusi P2;
END $$
DELIMITER ;

-- Dato un istante elenca gli operai al lavoro e relativi edifici
-- INPUT data e ora rispetto al quale effettuare l'operazione
-- OUTPUT resultset con operaio ed edificio

DELIMITER $$
CREATE PROCEDURE OperaiAlLavoro (IN Giorno1 DATE, IN Ora1 TIME)
BEGIN
	
    WITH LavoratoriAlLavoro AS (SELECT T.CodFiscale, T.ID
								FROM Turno T
								WHERE T.Giorno = Giorno1 AND T.OraInizio <= Ora1 AND T.OraFine > Ora1
	), StadioDiAvanzamentoUtile AS (SELECT F.ProgettoEdilizio, L.CodFiscale
								FROM Turnazione F
									INNER JOIN 
                                     LavoratoriAlLavoro L ON F.ID = L.ID
	), DatiLavoratore AS (SELECT L.Nome, L.Cognome, L.CodFiscale
						  FROM Lavoratore L
								INNER JOIN
							   LavoratoriAlLavoro L1 ON L.CodFiscale = L1.CodFiscale
	), EdificioUtile AS (SELECT P.CodEdificio, S.CodFiscale
						 FROM ProgettoEdilizio P
							  INNER JOIN
							  StadioDiAvanzamentoUtile S ON P.Codice = S.ProgettoEdilizio
	)
    SELECT D.Nome, D.Cognome, D.CodFiscale, E.CodEdificio
    FROM DatiLavoratore D
		INNER JOIN
         LavoratoriAlLavoro L ON D.CodFiscale = L.CodFiscale
		INNER JOIN
		 EdificioUtile E ON L.CodFiscale = E.CodFiscale;
							  
END $$
DELIMITER ;

-- Altezza Massima Edificio
-- INPUT CodEdificio
-- OUTPUT Altezza Edificio in metri

DELIMITER $$
CREATE PROCEDURE AltezzaMassimaEdificio (IN CodEdificio1 CHAR(21))
BEGIN
	
    WITH VaniEdificio AS (SELECT V.ID, V.CodEdificio, V.MaxAlt, V.Piano
						  FROM Vano V
                          WHERE V.CodEdificio = CodEdificio1
	), AltezzaMassimaPerPiano AS (SELECT V1.Piano, MAX(V1.MaxAlt) AS MaxAlt
								  FROM VaniEdificio V1
                                  GROUP BY V1.Piano
	)
    SELECT SUM(P.MaxAlt) AS AltezzaMassima
    FROM AltezzaMassimaPerPiano P;
			
END $$
DELIMITER ;

-- Data un'altezza verificare se gli edifici hanno i vani a norma
-- INPUT altezza
-- OUTPUT Nulla oppure i vani che non sono a norma

DELIMITER $$
CREATE PROCEDURE NormaVani (IN Altezza1 DECIMAL(5,2))
BEGIN
	
    WITH VaniNonANorma AS (SELECT V.ID, V.CodEdificio
									FROM Vano V
									WHERE V.MaxAlt < Altezza1
	)
    SELECT *
    FROM VaniNonANorma;
			
END $$
DELIMITER ;

-- Installazione Sensore
-- INPUT Codice sensore, tipo, soglia, asse x, asse y, muro, DataInstallazione
-- OUTPUT Inserimento o errore

DELIMITER $$
CREATE PROCEDURE INsensore (IN Codice1 CHAR(22), IN Tipo1 VARCHAR(45), IN Soglia1 FLOAT, IN AsseX1 FLOAT, IN AsseY1 FLOAT, IN ID1 CHAR(21),
							IN DataInstallazione1 DATE)

BEGIN
	
    IF AsseX1 > (SELECT M.Lunghezza
				 FROM Muro M
				 WHERE M.ID = ID1)
                 OR
	   AsseY1 > (SELECT M.Altezza
				 FROM Muro M
				 WHERE M.ID = ID1)
	THEN
    
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Impossibile inserire sensore: coordinate errate';
	
    ELSE
		
        INSERT INTO Sensore (Codice, ID, Tipo, DataInstallazione, SogliaDiSicurezza, CoordinataX, CoordinataY) VALUES (Codice1, ID1, Tipo1, DataInstallazione1, Soglia1, AsseX1, AsseY1);
	END IF;
END $$
DELIMITER ;