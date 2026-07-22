DROP PROCEDURE IF EXISTS Analytics2;
DELIMITER $$
CREATE PROCEDURE Analytics2 (IN CodEdificio1 CHAR(21), OUT valore_finale float)
BEGIN

DECLARE Contributo_Sensore FLOAT DEFAULT 40; -- 40 per cento
DECLARE Contributo_Stato FLOAT DEFAULT 60; -- 60 per cento
DECLARE Stringa VARCHAR(60);

SET Contributo_Sensore = (SELECT SUM(PercentualeSensori)*0.4
						  FROM (SELECT D.Numero, D.X, D.Y, D.Z, S.SogliaDiSicurezza, sqrt(D.X*D.X+D.Y*D.Y+D.Z*D.Z)/S.SogliaDiSicurezza AS PercentualeSensori
								FROM DatiRegistrati D
									 INNER JOIN
									 Sensore S ON D.Codice = S.Codice
								     INNER JOIN 
								     Formazione F ON S.ID = F.IDmuro             
						WHERE F.CodEdificio = CodEdificio1 AND S.Tipo = 'Triassiale') AS z);
                          
SET Contributo_Stato = (SELECT IF(E.Stato IS NULL, 0, E.Stato)/ 3 * 0.6 as PercentualeStato
						FROM Edificio E
                        WHERE E.Codice = CodEdificio1);
                                
SET valore_finale = IFNULL((Contributo_Sensore + Contributo_Stato)/15, 0 );

IF valore_finale = 0 THEN SET Stringa = 'Nessun rischio';
ELSE IF valore_finale <=3 THEN SET Stringa = 'Danni superficiali';
ELSE IF valore_finale <=5 THEN SET Stringa = 'Danni strutturali';
ELSE SET Stringa = 'Danni gravi alla struttura';
END IF;
END IF;
END IF;

SELECT valore_finale AS IndiceCalcolato, Stringa AS Messaggio;
END $$
DELIMITER ;