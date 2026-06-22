INSERT INTO tourist_profile (
    spice_tolerance,
    sweetness_preference,
    dietary_style_preferences,
    allergies,
    budget_band,
    consent_given,
    consent_date,
    data_purpose
)
VALUES (
    3,
    2,
    ARRAY['vegetarian'],
    ARRAY['peanut'],
    'medium',
    TRUE,
    CURRENT_TIMESTAMP,
    'Research evaluation and personalized culinary recommendations'
);

INSERT INTO canonical_food (
    name_en,
    name_si,
    cuisine_region,
    description_short,
    meal_slots,
    heaviness_score
)
VALUES (
    'Vegetable Kottu Roti',
    'එළවළු කොත්තු රොටි',
    'Western Province',
    'Chopped flatbread stir-fried with vegetables and spices.',
    ARRAY['lunch', 'dinner'],
    4.0
);

INSERT INTO ingredient (
    canonical_name,
    animal_plant_flag,
    allergen_group
)
VALUES
    ('Godamba Roti', 'plant', 'gluten'),
    ('Carrot', 'plant', NULL),
    ('Cabbage', 'plant', NULL);

INSERT INTO food_ingredient (
    food_id,
    ingredient_id,
    importance_rank,
    ingredient_role
)
VALUES
    (1, 1, 1, 'base'),
    (1, 2, 2, 'vegetable'),
    (1, 3, 3, 'vegetable');

INSERT INTO restaurant (
    name,
    address_text,
    district,
    location,
    price_band
)
VALUES (
    'Mock Colombo Restaurant',
    'Colombo, Sri Lanka',
    'Colombo',
    ST_SetSRID(
        ST_MakePoint(79.8612, 6.9271),
        4326
    )::GEOGRAPHY,
    'medium'
);

