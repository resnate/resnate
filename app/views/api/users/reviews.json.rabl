collection @reviews, :object_root => false

attributes *Review.column_names

extends "api/reviews/show"