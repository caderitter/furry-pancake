
DROP TABLE IF EXISTS Org CASCADE;
DROP TABLE IF EXISTS Meet CASCADE;
DROP TABLE IF EXISTS Participant CASCADE;
DROP TABLE IF EXISTS Swim CASCADE;
DROP TABLE IF EXISTS Heat CASCADE;
DROP TABLE IF EXISTS Event CASCADE;
DROP TABLE IF EXISTS Stroke CASCADE;
DROP TABLE IF EXISTS Distance CASCADE;

CREATE TABLE Org (
    id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50),
    is_univ BOOLEAN
);

CREATE TABLE Meet (
    name VARCHAR(50) PRIMARY KEY,
    start_date DATE NOT NULL,
    num_days INT NOT NULL,
    org_id VARCHAR(10),
    FOREIGN KEY (org_id) REFERENCES Org (id)
);

CREATE TABLE Participant (
    id VARCHAR(10) PRIMARY KEY,
    gender VARCHAR(1) NOT NULL,
    org_id VARCHAR(10),
    name VARCHAR(50),
    FOREIGN KEY (org_id) REFERENCES Org (id)
);

CREATE TABLE Stroke (
    stroke VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Distance (
    distance INT PRIMARY KEY
);

CREATE TABLE Event (
    id VARCHAR(10) PRIMARY KEY,
    gender VARCHAR(1) NOT NULL,
    stroke VARCHAR(50),
    distance INT,
    FOREIGN KEY (stroke) REFERENCES Stroke (stroke),
    FOREIGN KEY (distance) REFERENCES Distance (distance)
);

CREATE TABLE Heat (
    id INT,
    event_id VARCHAR(10),
    meet_name VARCHAR(50),
    PRIMARY KEY (id, event_id, meet_name),
    FOREIGN KEY (event_id) REFERENCES Event (id),
    FOREIGN KEY (meet_name) REFERENCES Meet (name)
);

CREATE TABLE Swim (
    heat_id INT,
    event_id VARCHAR(10),
    meet_name VARCHAR(50),
    participant_id VARCHAR(10),
    time FLOAT,
    PRIMARY KEY (heat_id, event_id, meet_name, participant_id),
    FOREIGN KEY (heat_id, event_id, meet_name) REFERENCES Heat (id, event_id, meet_name),
    FOREIGN KEY (participant_id) REFERENCES Participant (id)
);


DROP VIEW IF EXISTS Without_ranks CASCADE;
CREATE VIEW Without_ranks AS
SELECT s.meet_name, e.id AS event_id, e.gender AS event_gender, e.stroke, e.distance, h.id AS heat_id, p.id AS swimmer_id, p.name, o.id AS organization_id, o.name AS organization_name, s.time AS time
From Event e
INNER JOIN Heat h ON e.id = h.event_id
INNER JOIN Swim s ON s.heat_id = h.id AND s.event_id = h.event_id AND s.meet_name = h.meet_name
INNER JOIN Participant p ON s.participant_id = p.id
INNER JOIN Org o ON p.org_id = o.id;

DROP VIEW IF EXISTS With_ranks CASCADE;
CREATE VIEW With_ranks AS
SELECT w1.*, CASE WHEN w1.time IS NULL THEN NULL ELSE RANK() OVER (PARTITION BY w1.event_id, w1.meet_name ORDER BY w1.time ASC) END AS rank
FROM Without_ranks w1
LEFT OUTER JOIN Without_ranks w2
ON w1.event_id = w2.event_id AND w1.swimmer_id = w2.swimmer_id AND w1.time > w2.time
WHERE w2.event_id IS NULL
ORDER BY event_id, heat_id;


DROP FUNCTION IF EXISTS UpsertOrg (VARCHAR(10), VARCHAR(50), BOOLEAN);
CREATE OR REPLACE FUNCTION UpsertOrg (o_id VARCHAR(10),
                                      o_name VARCHAR(50), o_is_univ BOOLEAN)
RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Org (id, name, is_univ)
        VALUES (o_id, o_name, o_is_univ)
        ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name,
        is_univ = EXCLUDED.is_univ;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS UpsertMeet (VARCHAR(50), DATE, INT, VARCHAR(10));
CREATE OR REPLACE FUNCTION UpsertMeet (m_name VARCHAR(50), m_start_date DATE,
                                       m_num_days INT, m_org_id VARCHAR(10))
RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Meet (name, start_date, num_days, org_id)
        VALUES (m_name, m_start_date, m_num_days, m_org_id)
        ON CONFLICT (name) DO UPDATE SET start_date = EXCLUDED.start_date,
        num_days = EXCLUDED.num_days, org_id = EXCLUDED.org_id;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS UpsertParticipant (VARCHAR(10), VARCHAR(1), VARCHAR(10), VARCHAR(50));
CREATE OR REPLACE FUNCTION UpsertParticipant (p_id VARCHAR(10), p_gender VARCHAR(1),
                                             p_org_id VARCHAR(10), p_name VARCHAR(50))
RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Participant (id, gender, org_id, name)
        VALUES (p_id, p_gender, p_org_id, p_name)
        ON CONFLICT (id) DO UPDATE SET gender = EXCLUDED.gender,
        org_id = EXCLUDED.org_id, name = EXCLUDED.name;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS UpsertStroke (VARCHAR(50));
CREATE OR REPLACE FUNCTION UpsertStroke (s_stroke VARCHAR(50))
RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Stroke (stroke)
        VALUES (s_stroke)
        ON CONFLICT (stroke) DO UPDATE SET stroke = EXCLUDED.stroke;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS UpsertDistance (INT);
CREATE OR REPLACE FUNCTION UpsertDistance (d_distance INT)
RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Distance (distance)
        VALUES (d_distance)
        ON CONFLICT (distance) DO UPDATE SET distance = EXCLUDED.distance;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS UpsertEvent (VARCHAR(10), VARCHAR(1), VARCHAR(50), INT);
CREATE OR REPLACE FUNCTION UpsertEvent (e_id VARCHAR(10), e_gender VARCHAR(1), e_stroke VARCHAR(50), e_distance INT)
RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Event (id, gender, stroke, distance)
        VALUES (e_id, e_gender, e_stroke, e_distance)
        ON CONFLICT (id) DO UPDATE SET gender = EXCLUDED.gender,
        stroke = EXCLUDED.stroke, distance = EXCLUDED.distance;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS UpsertHeat (INT, VARCHAR(10), VARCHAR(50));
CREATE OR REPLACE FUNCTION UpsertHeat (h_id INT, h_event_id VARCHAR(10), h_meet_name VARCHAR(50))
RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Heat (id, event_id, meet_name)
        VALUES (h_id, h_event_id, h_meet_name)
        ON CONFLICT (id, event_id, meet_name) DO UPDATE SET id = EXCLUDED.id,
        event_id = EXCLUDED.event_id, meet_name = EXCLUDED.meet_name;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS UpsertSwim (INT, VARCHAR(10), VARCHAR(50), VARCHAR(10), FLOAT);
CREATE OR REPLACE FUNCTION UpsertSwim (s_heat_id INT, s_event_id VARCHAR(10), s_meet_name VARCHAR(50),
                                       s_participant_id VARCHAR(10), s_time FLOAT)
    RETURNS VOID
AS $$
    BEGIN
        INSERT INTO Swim (heat_id, event_id, meet_name, participant_id, time)
        VALUES (s_heat_id, s_event_id, s_meet_name, s_participant_id, s_time)
        ON CONFLICT (heat_id, event_id, meet_name, participant_id) DO UPDATE SET heat_id = EXCLUDED.heat_id,
        event_id = EXCLUDED.event_id, meet_name = EXCLUDED.meet_name, participant_id = EXCLUDED.participant_id,
        time = EXCLUDED.time;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS MeetHeetSheet (VARCHAR(50));
CREATE OR REPLACE FUNCTION MeetHeetSheet(m VARCHAR(50))
RETURNS TABLE (event_id VARCHAR(10), event_gender VARCHAR(1), stroke VARCHAR(50), distance INT,
               heat_id INT, swimmer_id VARCHAR(10), name VARCHAR(50), organization_id VARCHAR(10),
               organization_name VARCHAR(50), swim_time FLOAT, event_rank bigint)
AS $$
    BEGIN
        RETURN QUERY SELECT wo.event_id, wo.event_gender, wo.stroke, wo.distance, wo.heat_id, wo.swimmer_id,
        wo.name, wo.organization_id, wo.organization_name, wo.time, wi.rank AS event_rank
        From Without_ranks wo LEFT OUTER JOIN With_ranks wi
        ON wo.event_id=wi.event_id AND wo.heat_id = wi.heat_id AND wo.swimmer_id = wi.swimmer_id
        WHERE wo.meet_name = m
        ORDER BY event_id, heat_id;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS ParticipantMeetHeetSheet (VARCHAR(10), VARCHAR(50));
CREATE OR REPLACE FUNCTION ParticipantMeetHeetSheet(p VARCHAR(10), m VARCHAR(50))
RETURNS TABLE (event_id VARCHAR(10), event_gender VARCHAR(1), stroke VARCHAR(50), distance INT,
               heat_id INT, organization_id VARCHAR(10),
               organization_name VARCHAR(50), swim_time FLOAT, event_rank bigint)
AS $$
    BEGIN
        RETURN QUERY SELECT wo.event_id, wo.event_gender, wo.stroke, wo.distance, wo.heat_id,
        wo.organization_id, wo.organization_name, wo.time, wi.rank AS event_rank
        From Without_ranks wo LEFT OUTER JOIN With_ranks wi
        ON wo.event_id=wi.event_id AND wo.heat_id = wi.heat_id AND wo.swimmer_id = wi.swimmer_id
        WHERE wo.meet_name = m AND wo.swimmer_id = p
        ORDER BY event_id, heat_id;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS GetSwimmerID (VARCHAR(50));
CREATE OR REPLACE FUNCTION GetSwimmerID (swimmer_name VARCHAR(50))
RETURNS TABLE (swimmer_id VARCHAR(10), gender VARCHAR(1), organization_name VARCHAR(50))

AS $$
    BEGIN
        RETURN QUERY SELECT p.id, p.gender, o.name
        FROM Participant p, Org o
        WHERE p.name = swimmer_name AND p.org_id = o.id;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS GetSchoolID (VARCHAR(10));
CREATE OR REPLACE FUNCTION GetSchoolID (school_name VARCHAR(50))
RETURNS TABLE (school_id VARCHAR(10))

AS $$
    BEGIN
        RETURN QUERY SELECT id AS school_id
        FROM Org o
        WHERE o.name = school_name;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS SwimmerNamesSchoolMeetHeetSheet (VARCHAR(10), VARCHAR(50));
CREATE OR REPLACE FUNCTION SwimmerNamesSchoolMeetHeetSheet(s VARCHAR(10), m VARCHAR(50))
RETURNS TABLE (name VARCHAR(50))
AS $$
    BEGIN
        RETURN QUERY SELECT Distinct wo.name
        From Without_ranks wo
        WHERE wo.meet_name = m AND wo.organization_id = s;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS EventMeetHeetSheet (VARCHAR(10), VARCHAR(50));
CREATE OR REPLACE FUNCTION EventMeetHeetSheet(e VARCHAR(10), m VARCHAR(50))
RETURNS TABLE ( heat_id INT, swimmer_id VARCHAR(10), name VARCHAR(50), organization_id VARCHAR(10),
               organization_name VARCHAR(50), swim_time FLOAT, event_rank bigint)
AS $$
    BEGIN
        RETURN QUERY SELECT wo.heat_id, wo.swimmer_id,
        wo.name, wo.organization_id, wo.organization_name, wo.time, wi.rank AS event_rank
        From Without_ranks wo LEFT OUTER JOIN With_ranks wi
        ON wo.event_id=wi.event_id AND wo.heat_id = wi.heat_id AND wo.swimmer_id = wi.swimmer_id
        WHERE wo.meet_name = m AND wo.event_id = e
        ORDER BY time;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS RankToPoints (bigint);
CREATE OR REPLACE FUNCTION RankToPoints (rank bigint)
RETURNS INT
RETURNS NULL ON NULL INPUT
AS $$
    DECLARE
        points INT;
    BEGIN
        IF rank = 1 THEN
            points := 6;
        ELSEIF rank = 2 THEN
            points := 4;
        ELSEIF rank = 3 THEN
            points := 3;
        ELSEIF rank = 4 THEN
            points := 2;
        ELSEIF rank = 5 THEN
            points := 1;
        ELSE
            points := 0;
        END IF;
        RETURN points;
    END $$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS MeetScores (VARCHAR(50));
CREATE OR REPLACE FUNCTION MeetScores(m VARCHAR(50))
RETURNS TABLE (school_name VARCHAR(50), score bigint)
AS $$
    BEGIN
        RETURN QUERY SELECT wo.organization_name, SUM(RankToPoints(wi.rank)) AS score
        From Without_ranks wo LEFT OUTER JOIN With_ranks wi
        ON wo.event_id=wi.event_id AND wo.heat_id = wi.heat_id AND wo.swimmer_id = wi.swimmer_id
        WHERE wo.meet_name = m
        GROUP BY wo.organization_name
        ORDER BY score DESC;
    END $$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS GetColumns (VARCHAR(10));
CREATE OR REPLACE FUNCTION GetColumns (col VARCHAR(10))
RETURNS TABLE(column_name name, data_type text)
AS $$
    BEGIN
        RETURN QUERY SELECT attname, format_type(atttypid, atttypmod) AS type
        FROM   pg_attribute
        WHERE  attrelid = col ::regclass
        AND    attnum > 0
        AND    NOT attisdropped
        ORDER  BY attnum;
    END $$
LANGUAGE plpgsql;
