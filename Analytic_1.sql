DROP PROCEDURE IF EXISTS Analytics1;
DELIMITER $$
CREATE PROCEDURE Analytics1(CodEdificio CHAR(21))
BEGIN
	
	WITH VaniEdificioScelto AS(
		SELECT V.ID, E.Codice AS CodEdificio
		FROM Edificio E
			INNER JOIN 
            Vano V ON E.Codice = V.CodEdificio
		WHERE E.Codice = CodEdificio
	),
    MuriEdificioScelto AS (
		SELECT F.IDmuro, V.CodEdificio
        FROM VaniEdificioScelto V
			INNER JOIN
            Formazione F ON V.ID = F.IDvano AND V.CodEdificio = F.CodEdificio
	),
	SensoriScelti AS(
		SELECT S.Codice, S.SogliaDiSicurezza, S.ID, S.Tipo
		FROM Sensore S
			INNER JOIN
             MuriEdificioScelto M ON S.ID = M.IDmuro
	),
	MisurazioniValoreUnico AS(
		SELECT S.Codice, S.ID, (S.SogliaDiSicurezza-D.X)/S.SogliaDiSicurezza AS CoeffSingola
		FROM DatiRegistrati D
			INNER JOIN
             SensoriScelti S ON D.Codice = S.Codice
		WHERE S.Tipo <> 'Triassiale' AND D.X < S.SogliaDiSicurezza
	),
	MisurazioniTreValori AS(
		SELECT S.Codice, S.ID, NULLIF(S.SogliaDiSicurezza-Sqrt(D.X*D.X+D.Y*D.Y+D.Z*D.Z), 0)/S.SogliaDiSicurezza AS CoeffTripla
		FROM DatiRegistrati D 
			INNER JOIN
             SensoriScelti S ON D.Codice = S.Codice
		WHERE S.Tipo = 'Triassale' AND (D.X < SogliaDiSicurezza OR D.Y < SogliaDiSicurezza OR D.Z < SogliaDiSicurezza)
	),
	-- Calcolo il coeff. totale
	CoeffTOT AS(
		SELECT M.Codice, ID, Mis1, Coeff
		FROM (SELECT M1.Codice, M1.ID, COUNT(*) as Mis1, AVG(CoeffSingola) AS Coeff FROM MisurazioniValoreUnico M1 GROUP BY M1.Codice, M1.ID) AS M
			 UNION ALL
			 (SELECT M3.Codice, M3.ID, COUNT(*) as Mis1, AVG(CoeffTripla) AS Coeff FROM MisurazioniTreValori M3 GROUP BY M3.Codice, M3.ID)
	),
    CoeffRischio AS(
		SELECT S.Codice, S.ID, Mis1 AS Misura, SUM(Coeff)*100 AS CoeffRisc
        FROM SensoriScelti S 
			INNER JOIN
             CoeffTOT C ON S.Codice = C.Codice AND S.ID = C.ID
        GROUP BY S.Codice, S.ID, Mis1
    ),
	QuandoIntervenire AS(
		SELECT Codice, ID, CoeffRisc, IF(CoeffRisc=0, NULL, IF(CoeffRisc<=10, 12, IF(CoeffRisc<=25, 8, IF(CoeffRisc<=50, 4, IF(CoeffRisc<=75, 2, 'ASAP'))))) AS Mesi
		FROM CoeffRischio
	)
		
	SELECT *
	FROM QuandoIntervenire
	ORDER BY CoeffRisc DESC;
		
END $$
DELIMITER ;