SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema progetto basi di dati
-- -----------------------------------------------------

CREATE SCHEMA IF NOT EXISTS `Smart_Buildings_DB` DEFAULT CHARACTER SET utf8 ;
USE `Smart_Buildings_DB` ;

-- -----------------------------------------------------
-- Table `Edificio`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `Edificio` ;

CREATE TABLE IF NOT EXISTS `Edificio` (
	`Codice` 		CHAR(21) NOT NULL,
	`Stato`  		INT NULL, 
	`Tipologia` 	VARCHAR(45) NULL,
    `Latitudine` 	DECIMAL(9,6) NOT NULL,
    `Longitudine` 	DECIMAL(9,6) NOT NULL,
	PRIMARY KEY (`Codice`),
	FOREIGN KEY (`Latitudine`, `Longitudine`)
    REFERENCES Smart_Buildings_DB.`AreaGeografica` (`Latitudine`, `Longitudine`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `AreaGeografica`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `AreaGeografica` ;

CREATE TABLE IF NOT EXISTS `AreaGeografica` (
	`Latitudine` DECIMAL(9,6) NOT NULL, 
	`Longitudine` DECIMAL(9,6) NOT NULL,
  PRIMARY KEY (`Latitudine`,`Longitudine`)
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Vano`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Vano` ;

CREATE TABLE IF NOT EXISTS `Vano` (
	`ID` 	CHAR(21) NOT NULL,
    `CodEdificio` CHAR(21) NOT NULL,
	`Piano` 	INT NOT NULL,
	`MaxLun`  	DECIMAL(5,2) UNSIGNED NOT NULL,
    `MaxLarg` 	DECIMAL(5,2) UNSIGNED NOT NULL, 
	`MaxAlt`  	DECIMAL(5,2) UNSIGNED NOT NULL,
	`Funzione` 	VARCHAR(45) NULL,
    PRIMARY KEY (`ID`, `CodEdificio`),
	INDEX `fk_Vano_Edificio_idx` (`CodEdificio` ASC), 
    CONSTRAINT `fk_Vano_Edificio_idx`
    FOREIGN KEY (`CodEdificio`)
    REFERENCES Smart_Buildings_DB.`Edificio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Muro`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Muro` ;

CREATE TABLE IF NOT EXISTS `Muro` (
	`ID` 		CHAR(21) NOT NULL,
	`X_0` 		FLOAT NOT NULL,
    `Y_0` 		FLOAT NOT NULL,
    `X_1` 		FLOAT NOT NULL,
    `Y_1` 		FLOAT NOT NULL,
	`Formato`  	VARCHAR(16) NULL,
    `Altezza` 	DECIMAL(5,2) UNSIGNED NOT NULL, 
	`Lunghezza`  	DECIMAL(5,2) UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Formazione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Formazione` ;

CREATE TABLE IF NOT EXISTS `Formazione` (
	`IDvano` 		CHAR(21) NOT NULL,
    `IDmuro` 		CHAR(21) NOT NULL,
    `CodEdificio` 	CHAR(21) NOT NULL,
    PRIMARY KEY (`IDmuro`, `IDvano`, `CodEdificio`),
	INDEX `fk_Formazione_Vano_idx` (`IDvano` ASC, `CodEdificio` ASC),
    INDEX `fk_Formazione_Muro_idx` (`IDmuro` ASC),
    CONSTRAINT `fk_Formazione_Vano_idx`
    FOREIGN KEY (`IDvano`, `CodEdificio`)
    REFERENCES Smart_Buildings_DB.`Vano` (`ID`, `CodEdificio`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    CONSTRAINT `fk_Formazione_Muro_idx`
	FOREIGN KEY (`IDmuro`)
    REFERENCES Smart_Buildings_DB.`Muro` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `PuntoAccesso`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `PuntoAccesso` ;

CREATE TABLE IF NOT EXISTS `PuntoAccesso` (
    `ID` 	CHAR(21) NOT NULL,
	`Altezza`  	DECIMAL(5,2) UNSIGNED NOT NULL, 
    `Larghezza` 	DECIMAL(5,2) UNSIGNED NOT NULL, 
	`Tipo`  	VARCHAR(16) NULL,
    `DistanzaX`  	DECIMAL(5,2) UNSIGNED NOT NULL,
    `DistanzaY`  	DECIMAL(5,2) UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`,`DistanzaX`, `DistanzaY`),
    INDEX `fk_PuntoAccesso_Muro_idx` (`ID` ASC),
    CONSTRAINT `fk_PuntoAccesso_Muro_idx`
    FOREIGN KEY (`ID`)
    REFERENCES Smart_Buildings_DB.`Muro` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `ProgettoEdilizio`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ProgettoEdilizio` ;

CREATE TABLE IF NOT EXISTS `ProgettoEdilizio` (
	`Codice` 		CHAR(21) NOT NULL,
    `DataPresentazione`  DATE NOT NULL,
    `DataApprovazione` 	DATE NOT NULL,
	`DataInizio` 	DATE NOT NULL,
	`DataFine`  	DATE NOT NULL, 
    `StimaDataFine` DATE NOT NULL,
	`CostoLavori`  	DECIMAL(11,2) NOT NULL,
    `CodEdificio`  	CHAR(21) NOT NULL,
    PRIMARY KEY (`Codice`),
    FOREIGN KEY (`CodEdificio`)
    REFERENCES Smart_Buildings_DB.`Edificio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `StadioDiAvanzamento`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `StadioDiAvanzamento` ;

CREATE TABLE IF NOT EXISTS `StadioDiAvanzamento` (
	`Numero` 		INT NOT NULL,
    `ProgettoEdilizio`	CHAR(21) NOT NULL,
	`DataInizio` 	DATE NOT NULL,
	`DataFine`  	DATE NOT NULL, 
    `StimaDataFine` DATE NOT NULL,
	`Costo`  	DECIMAL(11,2) NOT NULL,
    `LavoriSvolti`  VARCHAR(500),
    PRIMARY KEY (`Numero`, `ProgettoEdilizio`),
    INDEX `fk_StadioDiAvanzamento_ProgettoEdilizio_idx` (`ProgettoEdilizio` ASC),
    CONSTRAINT `fk_StadioDiAvanzamento_ProgettoEdilizio_idx`
    FOREIGN KEY (`ProgettoEdilizio`)
    REFERENCES Smart_Buildings_DB.`ProgettoEdilizio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Turno`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Turno` ;

CREATE TABLE IF NOT EXISTS `Turno` (
	`ID` 		CHAR(21) NOT NULL,
    `Lavori`	VARCHAR(500) NULL,
    `MaxLavoratori` INT NOT NULL,
	`OraFine` 	TIME NOT NULL,
	`OraInizio`  TIME NOT NULL, 
    `Giorno` DATE NOT NULL,
    `CodFiscale` 	CHAR(21) NOT NULL,
    PRIMARY KEY (`ID`),
	FOREIGN KEY (`CodFiscale`)
    REFERENCES Smart_Buildings_DB.`Lavoratore` (`CodFiscale`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Turnazione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Turnazione` ;

CREATE TABLE IF NOT EXISTS `Turnazione` (
	`ID` 		CHAR(21) NOT NULL,
	`Numero` 		INT NOT NULL AUTO_INCREMENT,
    `ProgettoEdilizio`	CHAR(21) NOT NULL,
    PRIMARY KEY (`ID`, `Numero`, `ProgettoEdilizio`),
    INDEX `fk_Turnazione_StadioDiAvanzamento_idx` (`Numero` ASC, `ProgettoEdilizio` ASC),
    INDEX `fk_Turnazione_Turno_idx` (`ID` ASC),
    CONSTRAINT `fk_Turnazione_StadioDiAvanzamento_idx`
	FOREIGN KEY (`Numero`, `ProgettoEdilizio`)
    REFERENCES Smart_Buildings_DB.`StadioDiAvanzamento` (`Numero`, `ProgettoEdilizio`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    CONSTRAINT `fk_Turnazione_Turno_idx`
    FOREIGN KEY (`ID`)
    REFERENCES Smart_Buildings_DB.`Turno` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Lavoratore`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `Lavoratore` ;

CREATE TABLE IF NOT EXISTS `Lavoratore` (
	`CodFiscale` 	CHAR(21) NOT NULL,
	`Nome` 			VARCHAR(45) NOT NULL,
    `Cognome` 		VARCHAR(45) NOT NULL,
    `Stipendio`		DECIMAL(8,2) UNSIGNED NOT NULL,
    `CoefExp`		INT NOT NULL,
    PRIMARY KEY (`CodFiscale`)
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Materiale`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Materiale` ;

CREATE TABLE IF NOT EXISTS `Materiale` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    `Nome`				VARCHAR(45) NULL,
    `DataCompera` 		DATE NOT NULL,
    `Costo` 			DECIMAL(8,2) UNSIGNED NOT NULL,
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`)
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Mattone`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Mattone` ;

CREATE TABLE IF NOT EXISTS `Mattone` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    `X`				FLOAT UNSIGNED NULL,
    `Y` 		FLOAT UNSIGNED NULL,
    `Z` 			FLOAT UNSIGNED NULL,
	`Composizione` 			VARCHAR(45) NOT NULL,
    `Alveolatura` 			VARCHAR(45) NOT NULL,
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`),
    INDEX `fk_Mattone_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    CONSTRAINT `fk_Mattone_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;
-- -----------------------------------------------------
-- Table `Intonaco`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Intonaco` ;

CREATE TABLE IF NOT EXISTS `Intonaco` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    `Tipo`				VARCHAR(45) NOT NULL,
    `Colore` 			VARCHAR(45) NOT NULL,
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`),
    INDEX `fk_Intonaco_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    CONSTRAINT `fk_Intonaco_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Pietra`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Pietra` ;

CREATE TABLE IF NOT EXISTS `Pietra` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    `X`				FLOAT UNSIGNED NULL,
    `Y` 		FLOAT UNSIGNED NULL,
    `Z` 			FLOAT UNSIGNED NULL,
	`Tipo` 			VARCHAR(45) NOT NULL,
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`),
    INDEX `fk_Pietra_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    CONSTRAINT `fk_Pietra_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Piastrella`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Piastrella` ;

CREATE TABLE IF NOT EXISTS `Piastrella` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    `Poligono`			VARCHAR(45) NOT NULL,
    `Disegno` 			VARCHAR(45) NOT NULL,
    `NLati` 			INT NOT NULL,
    `Lato` 			FLOAT UNSIGNED NULL,
	`Tipo` 			VARCHAR(45) NOT NULL,
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`),
    INDEX `fk_Piastrella_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    CONSTRAINT `fk_Piastrella_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Legno`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Legno` ;

CREATE TABLE IF NOT EXISTS `Legno` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
	`Tipo` 			VARCHAR(45) NOT NULL,
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`),
    INDEX `fk_Legno_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    CONSTRAINT `fk_Legno_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `GeneraleP`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `GeneraleP` ;

CREATE TABLE IF NOT EXISTS `GeneraleP` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    `Peso`				DECIMAL(8,2) NOT NULL,
    `Funzione` 			VARCHAR(45) NOT NULL,
    `Descrizione` 		VARCHAR(500),
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`),
    INDEX `fk_GeneraleP_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    CONSTRAINT `fk_GeneraleP_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `GeneraleV`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `GeneraleV` ;

CREATE TABLE IF NOT EXISTS `GeneraleV` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    `X`				FLOAT UNSIGNED NULL,
    `Y` 		FLOAT UNSIGNED NULL,
    `Z` 			FLOAT UNSIGNED NULL,
	`Funzione` 			VARCHAR(45) NOT NULL,
    `Descrizione` 		VARCHAR(500),
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`),
    INDEX `fk_GeneraleV_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    CONSTRAINT `fk_GeneraleV_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION 
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Muratura`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Muratura` ;

CREATE TABLE IF NOT EXISTS `Muratura` (
	`Lato` 			VARCHAR(16) NOT NULL, -- n costituzione muro
	`Strato` 		INT NOT NULL,
    `ID`				CHAR(21) NOT NULL,
    `Spessore` 			FLOAT UNSIGNED NULL,
    `NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    PRIMARY KEY (`Lato`, `Strato`, `ID`),
    INDEX `fk_Muratura_Muro_idx` (`ID` ASC),
    CONSTRAINT `fk_Muratura_Muro_idx`
    FOREIGN KEY (`ID`)
    REFERENCES Smart_Buildings_DB.`Muro` (`ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
	FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Soffitto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Soffitto` ;

CREATE TABLE IF NOT EXISTS `Soffitto` (
    `Strato` INT NOT NULL,
    `ID` CHAR(21) NOT NULL,
    `CodEdificio` CHAR(21) NOT NULL,
    `Spessore` FLOAT UNSIGNED NULL,
    `NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    PRIMARY KEY (`Strato` , `ID` , `CodEdificio`),
    INDEX `fk_Soffitto_Vano_idx` (`ID` ASC, `CodEdificio` ASC),
    CONSTRAINT `fk_Soffitto_Vano_idx`
    FOREIGN KEY (`ID` , `CodEdificio`)
	REFERENCES Smart_Buildings_DB.`Vano` (`ID` , `CodEdificio`)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
	FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)  ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table `Pavimento`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Pavimento` ;

CREATE TABLE IF NOT EXISTS `Pavimento` (
    `ID` CHAR(21) NOT NULL,
    `CodEdificio` CHAR(21) NOT NULL,
    `Disposizione` VARCHAR(45) NOT NULL,
    `Fuga` FLOAT UNSIGNED NULL,
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
    PRIMARY KEY ( `ID` , `CodEdificio`),
    INDEX `fk_Pavimento_Vano_idx` (`ID` ASC, `CodEdificio` ASC),
    CONSTRAINT `fk_Pavimento_Vano_idx`
    FOREIGN KEY (`ID` , `CodEdificio`)
	REFERENCES Smart_Buildings_DB.`Vano` (`ID` , `CodEdificio`)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
	FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)  ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table `Sensore`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Sensore` ;

CREATE TABLE IF NOT EXISTS `Sensore` (
	`Codice` 	CHAR(22) NOT NULL,
    `ID` 	CHAR(21) NOT NULL,
	`Tipo` 		VARCHAR(45) NOT NULL,
    `DataInstallazione` 	DATE NOT NULL,
    `SogliaDiSicurezza` 	FLOAT NOT NULL,
	`CoordinataX` FLOAT NULL,
    `CoordinataY` FLOAT NULL,
    PRIMARY KEY (`Codice`),
    FOREIGN KEY (`ID`)
		REFERENCES Smart_Buildings_DB.`Muro` (`ID`)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `DatiRegistrati`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `DatiRegistrati` ;

CREATE TABLE IF NOT EXISTS `DatiRegistrati` (
	`Numero` 		INT NOT NULL AUTO_INCREMENT,
	`Codice` 		CHAR(22) NOT NULL,
	`X`				FLOAT UNSIGNED NULL,
    `Y` 			FLOAT UNSIGNED NULL,
    `Z` 			FLOAT UNSIGNED NULL,
    `Timestamp`		TIMESTAMP NOT NULL,
    PRIMARY KEY (`Numero`, `Codice`),
    INDEX `fk_DatiRegistrati_Sensore_idx` (`Codice` ASC),
    CONSTRAINT `fk_DatiRegistrati_Sensore_idx`
	FOREIGN KEY (`Codice`)
    REFERENCES Smart_Buildings_DB.`Sensore` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Alert`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Alert` ;

CREATE TABLE IF NOT EXISTS `Alert` (
	`Numero` 		INT NOT NULL AUTO_INCREMENT,
	`NumeroDatiReg` 	INT NOT NULL,
    `Codice` 		CHAR(22) NOT NULL,
    PRIMARY KEY (`Numero`, `NumeroDatiReg`, `Codice`),
    INDEX `fk_Alert_DatiRegistrati_idx` (`NumeroDatiReg` ASC,`Codice` ASC),
    CONSTRAINT `fk_Alert_DatiRegistrati_idx`
	FOREIGN KEY (`NumeroDatiReg`, `Codice`)
    REFERENCES Smart_Buildings_DB.`DatiRegistrati` (`Numero`, `Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `RischioGeologico`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `RischioGeologico` ;

CREATE TABLE IF NOT EXISTS `RischioGeologico` (
	`Tipologia` 	VARCHAR(45) NOT NULL,
    `CoefRischio` 		FLOAT NOT NULL,
    `Latitudine` DECIMAL(9,6) NOT NULL, 
	`Longitudine` DECIMAL(9,6) NOT NULL,
    PRIMARY KEY (`Tipologia`, `Latitudine`, `Longitudine`),
    INDEX `fk_RischioGeologico_AreaGeografica_idx` (`Latitudine` ASC, `Longitudine` ASC),
    CONSTRAINT `fk_RischioGeologico_AreaGeografica_idx`
	FOREIGN KEY (`Latitudine`, `Longitudine`)
    REFERENCES Smart_Buildings_DB.`AreaGeografica` (`Latitudine`, `Longitudine`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `EventoCalamitoso`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `EventoCalamitoso` ;

CREATE TABLE IF NOT EXISTS `EventoCalamitoso` (
	`Nome` 				VARCHAR(45) NOT NULL,
	`DataAccadimento` 	DATE NOT NULL,
    `CoefGravita` 		FLOAT NOT NULL,
    `Tipo` 				VARCHAR(45) NOT NULL,
    PRIMARY KEY (`Nome`)
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Localizzazione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Localizzazione` ;

CREATE TABLE IF NOT EXISTS `Localizzazione` (
    `Latitudine` DECIMAL(9,6) NOT NULL, 
    `Longitudine` DECIMAL(9,6) NOT NULL,
	`Nome` VARCHAR(45) NOT NULL,
    PRIMARY KEY (`Nome`, `Latitudine`, `Longitudine`),
    INDEX `fk_Localizzazione_AreaGeografica_idx` (`Latitudine` ASC, `Longitudine` ASC),
    INDEX `fk_Localizzazione_EventoCalamitoso_idx` (`Nome` ASC),
    CONSTRAINT `fk_Localizzazione_AreaGeografica_idx`
    FOREIGN KEY (`Latitudine`, `Longitudine`)
    REFERENCES Smart_Buildings_DB.`AreaGeografica` (`Latitudine`, `Longitudine`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    CONSTRAINT `fk_Localizzazione_EventoCalamitoso_idx`
    FOREIGN KEY (`Nome`)
    REFERENCES Smart_Buildings_DB.`EventoCalamitoso` (`Nome`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Impiego`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Impiego` ;

CREATE TABLE IF NOT EXISTS `Impiego` (
	`NomeFornitore` 	VARCHAR(45) NOT NULL,
	`CodProdotto` 		CHAR(21) NOT NULL,
	`ProgettoEdilizio`	CHAR(21) NOT NULL,
    PRIMARY KEY (`NomeFornitore`, `CodProdotto`, `ProgettoEdilizio`),
    INDEX `fk_Impiego_Materiale_idx` (`NomeFornitore` ASC, `CodProdotto` ASC),
    INDEX `fk_Impiego_ProgettoEdilizio_idx` (`ProgettoEdilizio` ASC),
    CONSTRAINT `fk_Impiego_Materiale_idx`
    FOREIGN KEY (`NomeFornitore`, `CodProdotto`)
    REFERENCES Smart_Buildings_DB.`Materiale` (`NomeFornitore`, `CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    CONSTRAINT `fk_Impiego_ProgettoEdilizio_idx`
    FOREIGN KEY (`ProgettoEdilizio`)
    REFERENCES Smart_Buildings_DB.`ProgettoEdilizio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;