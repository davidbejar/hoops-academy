package persistence

// optional is an id's text, or nil (no filter, no value).
func optional[T interface{ String() string }](id *T) *string {
	if id == nil {
		return nil
	}
	text := (*id).String()
	return &text
}

// optionalText is a code's text (a status, a category), or nil.
func optionalText[T ~string](code *T) *string {
	if code == nil {
		return nil
	}
	text := string(*code)
	return &text
}

// idTexts are the ids' texts, for a uuid[] parameter.
func idTexts[T interface{ String() string }](ids []T) []string {
	out := make([]string, len(ids))
	for i, id := range ids {
		out[i] = id.String()
	}
	return out
}
