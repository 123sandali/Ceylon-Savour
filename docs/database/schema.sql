CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE tourist_profile (
    tourist_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    session_id UUID NOT NULL DEFAULT gen_random_uuid(),
    nationality_code VARCHAR(3),

    spice_tolerance SMALLINT,
    sweetness_preference SMALLINT,
    sourness_preference SMALLINT,
    coconut_preference SMALLINT,
    novelty_preference SMALLINT,
    comfort_preference SMALLINT,

    dietary_style_preferences TEXT[] NOT NULL DEFAULT '{}',
    allergies TEXT[] NOT NULL DEFAULT '{}',
    disliked_ingredients TEXT[] NOT NULL DEFAULT '{}',

    budget_band VARCHAR(20),

    consent_given BOOLEAN NOT NULL DEFAULT FALSE,
    consent_date TIMESTAMPTZ,
    data_purpose TEXT NOT NULL,
    deletion_requested BOOLEAN NOT NULL DEFAULT FALSE,
    deletion_date TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_tourist_profile_session UNIQUE (session_id),

    CONSTRAINT chk_spice_tolerance
        CHECK (spice_tolerance BETWEEN 1 AND 5),

    CONSTRAINT chk_sweetness_preference
        CHECK (sweetness_preference BETWEEN 1 AND 5),

    CONSTRAINT chk_sourness_preference
        CHECK (sourness_preference BETWEEN 1 AND 5),

    CONSTRAINT chk_coconut_preference
        CHECK (coconut_preference BETWEEN 1 AND 5),

    CONSTRAINT chk_novelty_preference
        CHECK (novelty_preference BETWEEN 1 AND 5),

    CONSTRAINT chk_comfort_preference
        CHECK (comfort_preference BETWEEN 1 AND 5),

    CONSTRAINT chk_consent_date
        CHECK (
            (consent_given = FALSE AND consent_date IS NULL)
            OR
            (consent_given = TRUE AND consent_date IS NOT NULL)
        ),

    CONSTRAINT chk_deletion_date
        CHECK (
            (deletion_requested = FALSE AND deletion_date IS NULL)
            OR
            (deletion_requested = TRUE AND deletion_date IS NOT NULL)
        )
);

CREATE TRIGGER trg_tourist_profile_updated_at
BEFORE UPDATE ON tourist_profile
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE canonical_food (
    food_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name_en VARCHAR(200) NOT NULL,
    name_si VARCHAR(200),
    name_ta VARCHAR(200),

    cuisine_region VARCHAR(100),
    cuisine_country VARCHAR(100) NOT NULL DEFAULT 'Sri Lanka',

    description_short TEXT,
    image_ref TEXT,

    meal_slots TEXT[] NOT NULL DEFAULT '{}',
    heaviness_score NUMERIC(3,2),
    serving_size_g NUMERIC(8,2),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_food_heaviness
        CHECK (heaviness_score BETWEEN 0 AND 5),

    CONSTRAINT chk_food_serving_size
        CHECK (serving_size_g IS NULL OR serving_size_g > 0)
);

CREATE TRIGGER trg_canonical_food_updated_at
BEFORE UPDATE ON canonical_food
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE ingredient (
    ingredient_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    canonical_name VARCHAR(200) NOT NULL,
    alternative_names TEXT[] NOT NULL DEFAULT '{}',

    animal_plant_flag VARCHAR(20),
    allergen_group VARCHAR(100),
    ingredient_origin_type VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_ingredient_name UNIQUE (canonical_name),

    CONSTRAINT chk_ingredient_type
        CHECK (
            animal_plant_flag IS NULL
            OR animal_plant_flag IN (
                'plant',
                'animal',
                'fungal',
                'mineral',
                'mixed',
                'unknown'
            )
        )
);

CREATE TRIGGER trg_ingredient_updated_at
BEFORE UPDATE ON ingredient 
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE food_ingredient (
    food_id BIGINT NOT NULL,
    ingredient_id BIGINT NOT NULL,

    importance_rank SMALLINT,
    is_optional BOOLEAN NOT NULL DEFAULT FALSE,
    ingredient_role VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (food_id, ingredient_id),

    CONSTRAINT fk_food_ingredient_food
        FOREIGN KEY (food_id)
        REFERENCES canonical_food(food_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_food_ingredient_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient(ingredient_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_importance_rank
        CHECK (importance_rank IS NULL OR importance_rank > 0)
);

CREATE TRIGGER trg_food_ingredient_updated_at
BEFORE UPDATE ON food_ingredient
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE nutrition_profile (
    nutrition_profile_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    food_id BIGINT NOT NULL,

    kcal_100g NUMERIC(8,2),
    carbohydrates_g NUMERIC(8,2),
    protein_g NUMERIC(8,2),
    fat_g NUMERIC(8,2),
    fiber_g NUMERIC(8,2),
    sodium_mg NUMERIC(8,2),
    sugar_g NUMERIC(8,2),

    confidence_score NUMERIC(4,3),
    confidence_label VARCHAR(50),
    source TEXT,
    last_verified TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_nutrition_food UNIQUE (food_id),

    CONSTRAINT fk_nutrition_food
        FOREIGN KEY (food_id)
        REFERENCES canonical_food(food_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_nutrition_confidence
        CHECK (
            confidence_score IS NULL
            OR confidence_score BETWEEN 0 AND 1
        )
);

CREATE TRIGGER trg_nutrition_profile_updated_at
BEFORE UPDATE ON nutrition_profile
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE taste_profile (
    taste_profile_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    food_id BIGINT NOT NULL,

    spice_base NUMERIC(3,2),
    sweetness NUMERIC(3,2),
    sourness NUMERIC(3,2),
    saltiness NUMERIC(3,2),
    bitterness NUMERIC(3,2),
    coconut_intensity NUMERIC(3,2),
    oiliness NUMERIC(3,2),
    friedness NUMERIC(3,2),
    umami NUMERIC(3,2),

    aroma_tags TEXT[] NOT NULL DEFAULT '{}',
    texture_tags TEXT[] NOT NULL DEFAULT '{}',

    confidence_score NUMERIC(4,3),
    confidence_label VARCHAR(50),
    source TEXT,
    last_verified TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_taste_food UNIQUE (food_id),

    CONSTRAINT fk_taste_food
        FOREIGN KEY (food_id)
        REFERENCES canonical_food(food_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_taste_spice
        CHECK (spice_base IS NULL OR spice_base BETWEEN 0 AND 5),

    CONSTRAINT chk_taste_sweetness
        CHECK (sweetness IS NULL OR sweetness BETWEEN 0 AND 5),

    CONSTRAINT chk_taste_sourness
        CHECK (sourness IS NULL OR sourness BETWEEN 0 AND 5),

    CONSTRAINT chk_taste_saltiness
        CHECK (saltiness IS NULL OR saltiness BETWEEN 0 AND 5),

    CONSTRAINT chk_taste_bitterness
        CHECK (bitterness IS NULL OR bitterness BETWEEN 0 AND 5),

    CONSTRAINT chk_taste_confidence
        CHECK (
            confidence_score IS NULL
            OR confidence_score BETWEEN 0 AND 1
        )
);

CREATE TRIGGER trg_taste_profile_updated_at
BEFORE UPDATE ON taste_profile
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE dietary_safety (
    dietary_safety_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    food_id BIGINT NOT NULL,

    vegetarian BOOLEAN,
    vegan BOOLEAN,
    halal_possible BOOLEAN,
    gluten_free_possible BOOLEAN,

    contains_seafood BOOLEAN NOT NULL DEFAULT FALSE,
    contains_beef BOOLEAN NOT NULL DEFAULT FALSE,
    contains_pork BOOLEAN NOT NULL DEFAULT FALSE,
    contains_egg BOOLEAN NOT NULL DEFAULT FALSE,
    contains_dairy BOOLEAN NOT NULL DEFAULT FALSE,
    contains_nuts BOOLEAN NOT NULL DEFAULT FALSE,

    allergen_tags TEXT[] NOT NULL DEFAULT '{}',
    safety_notes TEXT,
    source TEXT,
    last_verified TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_dietary_safety_food UNIQUE (food_id),

    CONSTRAINT fk_dietary_safety_food
        FOREIGN KEY (food_id)
        REFERENCES canonical_food(food_id)
        ON DELETE CASCADE
);

CREATE TRIGGER trg_dietary_safety_updated_at
BEFORE UPDATE ON dietary_safety
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE restaurant (
    restaurant_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name VARCHAR(200) NOT NULL,
    address_text TEXT,
    district VARCHAR(100),

    location GEOGRAPHY(POINT, 4326) NOT NULL,

    opening_hours JSONB,
    service_modes TEXT[] NOT NULL DEFAULT '{}',

    contact_no VARCHAR(50),
    google_place_id VARCHAR(255),
    price_band VARCHAR(20),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_restaurant_google_place
        UNIQUE NULLS NOT DISTINCT (google_place_id)
);

CREATE TRIGGER trg_restaurant_updated_at
BEFORE UPDATE ON restaurant
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE restaurant_menu_offer (
    offer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    restaurant_id BIGINT NOT NULL,
    food_id BIGINT NOT NULL,

    display_name VARCHAR(200),
    price NUMERIC(10,2),
    currency_code CHAR(3) NOT NULL DEFAULT 'LKR',

    availability_window VARCHAR(100),
    available_days TEXT[] NOT NULL DEFAULT '{}',
    portion_size_text VARCHAR(100),
    preparation_time_min INTEGER,

    active_from DATE,
    active_to DATE,

    is_available BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_offer_restaurant
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurant(restaurant_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_offer_food
        FOREIGN KEY (food_id)
        REFERENCES canonical_food(food_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_offer_price
        CHECK (price IS NULL OR price >= 0),

    CONSTRAINT chk_offer_dates
        CHECK (
            active_to IS NULL
            OR active_from IS NULL
            OR active_to >= active_from
        )
);

CREATE TRIGGER trg_restaurant_menu_offer_updated_at
BEFORE UPDATE ON restaurant_menu_offer
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE restaurant_modifier (
    modifier_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offer_id BIGINT NOT NULL,

    spice_override NUMERIC(3,2),
    sweetness_override NUMERIC(3,2),
    oiliness_override NUMERIC(3,2),

    ingredient_additions TEXT[] NOT NULL DEFAULT '{}',
    ingredient_removals TEXT[] NOT NULL DEFAULT '{}',

    portion_multiplier NUMERIC(5,2),
    authenticity_override NUMERIC(3,2),

    safety_note TEXT,
    price_override_note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_modifier_offer
        FOREIGN KEY (offer_id)
        REFERENCES restaurant_menu_offer(offer_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_modifier_spice
        CHECK (
            spice_override IS NULL
            OR spice_override BETWEEN 0 AND 5
        ),

    CONSTRAINT chk_modifier_portion
        CHECK (
            portion_multiplier IS NULL
            OR portion_multiplier > 0
        )
);

CREATE TRIGGER trg_restaurant_modifier_updated_at
BEFORE UPDATE ON restaurant_modifier
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE attraction (
    attraction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    district VARCHAR(100),

    location GEOGRAPHY(POINT, 4326) NOT NULL,

    opening_hours JSONB,
    fee_required BOOLEAN NOT NULL DEFAULT FALSE,
    typical_dwell_min INTEGER,
    popularity_score NUMERIC(5,2),

    source TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_attraction_dwell
        CHECK (
            typical_dwell_min IS NULL
            OR typical_dwell_min > 0
        )
);

CREATE TRIGGER trg_attraction_updated_at
BEFORE UPDATE ON attraction
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE itinerary_context (
    trip_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tourist_id BIGINT NOT NULL,

    trip_date DATE NOT NULL,
    meal_slot VARCHAR(20),

    anchor_location GEOGRAPHY(POINT, 4326) NOT NULL,

    time_window_start TIME,
    time_window_end TIME,

    budget_band VARCHAR(20),
    transport_mode VARCHAR(30),
    activity_type VARCHAR(100),
    expected_walking_level VARCHAR(30),
    weather_context VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_itinerary_tourist
        FOREIGN KEY (tourist_id)
        REFERENCES tourist_profile(tourist_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_itinerary_time
        CHECK (
            time_window_end IS NULL
            OR time_window_start IS NULL
            OR time_window_end > time_window_start
        ),

    CONSTRAINT chk_meal_slot
        CHECK (
            meal_slot IS NULL
            OR meal_slot IN (
                'breakfast',
                'morning_snack',
                'lunch',
                'afternoon_snack',
                'dinner',
                'late_night'
            )
        )
);

CREATE TRIGGER trg_itinerary_context_updated_at
BEFORE UPDATE ON itinerary_context
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_food_ingredient_food_id
    ON food_ingredient(food_id);

CREATE INDEX idx_food_ingredient_ingredient_id
    ON food_ingredient(ingredient_id);

CREATE INDEX idx_nutrition_profile_food_id
    ON nutrition_profile(food_id);

CREATE INDEX idx_taste_profile_food_id
    ON taste_profile(food_id);

CREATE INDEX idx_dietary_safety_food_id
    ON dietary_safety(food_id);

CREATE INDEX idx_menu_offer_restaurant_id
    ON restaurant_menu_offer(restaurant_id);

CREATE INDEX idx_menu_offer_food_id
    ON restaurant_menu_offer(food_id);

CREATE INDEX idx_restaurant_modifier_offer_id
    ON restaurant_modifier(offer_id);

CREATE INDEX idx_itinerary_context_tourist_id
    ON itinerary_context(tourist_id);

CREATE INDEX idx_restaurant_location_gist
    ON restaurant
    USING GIST (location);

CREATE INDEX idx_attraction_location_gist
    ON attraction
    USING GIST (location);

CREATE INDEX idx_itinerary_anchor_location_gist
    ON itinerary_context
    USING GIST (anchor_location);

