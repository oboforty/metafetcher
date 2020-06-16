
remigrate_hmdb <- function (conn) {
  # temporal: delete table
  if (dbExistsTable(conn, "hmdb_data")) {
    dbRemoveTable(conn, "hmdb_data")
  }

  # recreate table
  dbGetQuery(conn, "CREATE TABLE hmdb_data (
	hmdb_id VARCHAR(20) NOT NULL,
	hmdb_id_alt VARCHAR(20)[],
	names TEXT[],
	description TEXT,
	avg_mol_weight FLOAT,
	monoisotopic_mol_weight FLOAT,
	state VARCHAR(32),
	formula TEXT,
	smiles TEXT,
	inchi TEXT,
	inchikey TEXT,
	chemspider_id VARCHAR(32),
	kegg_id VARCHAR(32),
	metlin_id VARCHAR(32),
	pubchem_id VARCHAR(32),
	chebi_id VARCHAR(20),

	PRIMARY KEY (hmdb_id)
  )")
}



remigrate_chebi <- function (conn) {
  # temporal: delete table
  if (dbExistsTable(conn, "chebi_data")) {
    dbRemoveTable(conn, "chebi_data")
  }

  # recreate table
  dbGetQuery(conn, "CREATE TABLE chebi_data (
	names TEXT[],
	formula TEXT,
	smiles TEXT,
	inchi TEXT,
	inchikey TEXT,
	chebi_id VARCHAR(20) NOT NULL,
	chebi_id_alt VARCHAR(20)[],

	description TEXT,
	quality INTEGER,
	comments TEXT,
	cas_id VARCHAR(20),
	kegg_id VARCHAR(20),
	hmdb_id VARCHAR(20),
	lipidmaps_id VARCHAR(20),
	pubchem_id VARCHAR(20),
	charge FLOAT,
	mass FLOAT,
	monoisotopic_mass FLOAT,
	list_of_pathways TEXT,
	kegg_details TEXT,

	PRIMARY KEY (chebi_id)
  )")
}

remigrate_lipidmaps <- function (conn) {
  # temporal: delete table
  if (dbExistsTable(conn, "lipidmaps_data")) {
    dbRemoveTable(conn, "lipidmaps_data")
  }

  # recreate table
  dbGetQuery(conn, "CREATE TABLE lipidmaps_data (
	lipidmaps_id VARCHAR(20) NOT NULL,
	names TEXT[],
	category VARCHAR(32),
	main_class VARCHAR(64),
	sub_class VARCHAR(128),
	lvl4_class VARCHAR(128),
	mass FLOAT,
	smiles TEXT,
	inchi TEXT,
	inchikey VARCHAR(27),
	formula VARCHAR(256),
	kegg_id VARCHAR(20),
	hmdb_id VARCHAR(20),
	chebi_id VARCHAR(20),
	pubchem_id VARCHAR(20),
	lipidbank_id VARCHAR(20),

	PRIMARY KEY (lipidmaps_id)
  )")
}

add_foreign_keys <- function () {

}
