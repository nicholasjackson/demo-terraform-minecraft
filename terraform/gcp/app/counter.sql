\c minecraft;
CREATE TABLE counter (
  count INT NOT NULL
);

ALTER TABLE counter OWNER TO postgres;

INSERT INTO counter (count) VALUES (0);