-- Populate Categories and Subcategories
-- Run this AFTER running CLEAN_SETUP_COMPLETE.sql

-- Insert Categories
INSERT INTO public.categories (id, name, sort_order) VALUES
  (gen_random_uuid(), 'Food & Dining', 1),
  (gen_random_uuid(), 'Transportation', 2),
  (gen_random_uuid(), 'Accommodation', 3),
  (gen_random_uuid(), 'Activities & Entertainment', 4),
  (gen_random_uuid(), 'Shopping', 5),
  (gen_random_uuid(), 'Travel Essentials', 6),
  (gen_random_uuid(), 'Health & Medical', 7),
  (gen_random_uuid(), 'Communication', 8),
  (gen_random_uuid(), 'Tips & Gratuities', 9),
  (gen_random_uuid(), 'Banking & Fees', 10),
  (gen_random_uuid(), 'Personal Care', 11),
  (gen_random_uuid(), 'Miscellaneous', 12),
  (gen_random_uuid(), 'Prostitution', 13)
ON CONFLICT (name) DO NOTHING;

-- Insert Subcategories for Food & Dining
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Restaurant', 1), ('Fast Food', 2), ('Street Food', 3), ('Cafe/Coffee', 4),
  ('Bar/Pub', 5), ('Alcohol', 6), ('Groceries', 7), ('Snacks', 8),
  ('Breakfast', 9), ('Lunch', 10), ('Dinner', 11), ('Room Service', 12),
  ('Delivery', 13), ('Other', 14)
) AS sub(name, sort_order)
WHERE c.name = 'Food & Dining'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Transportation
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Flights', 1), ('Trains', 2), ('Buses', 3), ('Taxis/Ride Share/Bolt/Grab', 4),
  ('Car Rental', 5), ('Fuel/Gas', 6), ('Parking', 7), ('Tolls', 8),
  ('Metro/Subway', 9), ('Ferry/Boat', 10), ('Airport Transfer', 11),
  ('Local Transport', 12), ('Bike Rental', 13), ('Scooter Rental', 14), ('Other', 15)
) AS sub(name, sort_order)
WHERE c.name = 'Transportation'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Accommodation
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Hotel', 1), ('Hostel', 2), ('Airbnb', 3), ('Resort', 4),
  ('Camping', 5), ('Guesthouse', 6), ('Apartment Rental', 7),
  ('Villa', 8), ('Lodge', 9), ('Homestay', 10), ('Other', 11)
) AS sub(name, sort_order)
WHERE c.name = 'Accommodation'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Activities & Entertainment
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Tours', 1), ('Museums', 2), ('Theme Parks', 3), ('Adventure Sports', 4),
  ('Water Sports', 5), ('Skiing', 6), ('Hiking', 7), ('Sightseeing', 8),
  ('Concerts/Shows', 9), ('Movies', 10), ('Events', 11), ('Attractions', 12),
  ('Excursions', 13), ('Guided Tours', 14), ('Entry Fees', 15), ('Other', 16)
) AS sub(name, sort_order)
WHERE c.name = 'Activities & Entertainment'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Shopping
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Souvenirs', 1), ('Clothing', 2), ('Electronics', 3), ('Local Products', 4),
  ('Duty Free', 5), ('Books', 6), ('Gifts', 7), ('Art & Crafts', 8),
  ('Jewelry', 9), ('Accessories', 10), ('Other', 11)
) AS sub(name, sort_order)
WHERE c.name = 'Shopping'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Travel Essentials
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Travel Insurance', 1), ('Visa Fees', 2), ('Passport/ID', 3),
  ('Travel Documents', 4), ('SIM Card', 5), ('Travel Adapter', 6),
  ('Luggage', 7), ('Travel Gear', 8), ('Other', 9)
) AS sub(name, sort_order)
WHERE c.name = 'Travel Essentials'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Health & Medical
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Pharmacy', 1), ('Medication', 2), ('Doctor Visit', 3),
  ('Medical Insurance', 4), ('First Aid', 5), ('Vaccinations', 6),
  ('Health Check', 7), ('Travel Insurance', 8), ('Other', 9)
) AS sub(name, sort_order)
WHERE c.name = 'Health & Medical'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Communication
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Phone/Data', 1), ('WiFi', 2), ('Internet', 3),
  ('Roaming', 4), ('SIM Card', 5), ('Other', 6)
) AS sub(name, sort_order)
WHERE c.name = 'Communication'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Tips & Gratuities
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Hotel Staff', 1), ('Restaurant', 2), ('Tour Guide', 3),
  ('Driver', 4), ('Porter', 5), ('Housekeeping', 6), ('Other', 7)
) AS sub(name, sort_order)
WHERE c.name = 'Tips & Gratuities'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Banking & Fees
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('ATM Fees', 1), ('Currency Exchange', 2), ('Bank Charges', 3),
  ('Transaction Fees', 4), ('Credit Card Fees', 5), ('Other', 6)
) AS sub(name, sort_order)
WHERE c.name = 'Banking & Fees'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Personal Care
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Haircut', 1), ('Spa/Massage', 2), ('Salon', 3),
  ('Toiletries', 4), ('Laundry', 5), ('Dry Cleaning', 6), ('Other', 7)
) AS sub(name, sort_order)
WHERE c.name = 'Personal Care'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Miscellaneous
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Lost & Found', 1), ('Emergency', 2), ('Storage', 3),
  ('Locker', 4), ('Other', 5)
) AS sub(name, sort_order)
WHERE c.name = 'Miscellaneous'
ON CONFLICT (category_id, name) DO NOTHING;

-- Insert Subcategories for Prostitution
INSERT INTO public.subcategories (category_id, name, sort_order)
SELECT c.id, sub.name, sub.sort_order
FROM public.categories c,
(VALUES
  ('Prostitutes', 1), ('Strip Clubs', 2), ('Sex Workers', 3), ('Other', 4)
) AS sub(name, sort_order)
WHERE c.name = 'Prostitution'
ON CONFLICT (category_id, name) DO NOTHING;

