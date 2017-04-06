DROP TABLE IF EXISTS Org;
DROP TABLE IF EXISTS Meet;
DROP TABLE IF EXISTS Participant;
DROP TABLE IF EXISTS Swim;
DROP TABLE IF EXISTS Heat;
DROP TABLE IF EXISTS Event;
DROP TABLE IF EXISTS Stroke;
DROP TABLE IF EXISTS Distance;

CREATE TABLE Org (
	id INT PRIMARY KEY,
	name VARCHAR(50),
	is_univ BOOLEAN
);

CREATE TABLE Meet (
	name VARCHAR(50) PRIMARY KEY,
	start_date INT NOT NULL,
	num_days INT NOT NULL,
	org_id INT,
	FOREIGN KEY (org_id) REFERENCES Org (id)
);

CREATE TABLE Participant (
	id INT PRIMARY KEY,
	gender VARCHAR(1) NOT NULL,
	org_id INT,
	FOREIGN KEY (org_id) REFERENCES Org (id) 
);

CREATE TABLE Stroke (
	stroke VARCHAR(50)
);

CREATE TABLE Distance (
	distance INT PRIMARY KEY,
);

CREATE TABLE Event (
	id INT PRIMARY KEY,
	gender VARCHAR(1) NOT NULL,
	FOREIGN KEY (stroke) REFERENCES Stroke (stroke),
	FOREIGN KEY (distance) REFERENCES Distance (distance)
);

CREATE TABLE Heat (
	id INT PRIMARY KEY 
	FOREIGN KEY (event_id) REFERENCES Event (id),
	FOREIGN KEY (meet_name) REFERENCES Meet (name)
);

CREATE TABLE Swim ( 
	FOREIGN KEY (heat_id, event_id, meet_name) REFERENCES Heat (id, event_id, meet_name),
	FOREIGN KEY (participant_id) REFERENCES Participant (id)
);






