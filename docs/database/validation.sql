-- BEGIN;

-- SAVEPOINT invalid_fk_test;

-- INSERT INTO food_ingredient (
--     food_id,
--     ingredient_id
-- )
-- VALUES (
--     999999,
--     999999
-- );

-- ROLLBACK TO SAVEPOINT invalid_fk_test;

-- COMMIT;

-- INSERT INTO tourist_profile (
--     consent_given,
--     consent_date,
--     data_purpose
-- )
-- VALUES (
--     TRUE,
--     NULL,
--     'Testing'
-- );


INSERT INTO taste_profile (
    food_id,
    spice_base
)
VALUES (
    1,
    9
);