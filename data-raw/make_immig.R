# Create the immig example dataset from the full immigration conjoint
# Full data: ~1400 respondents × 5 tasks × 2 profiles = 13,960 rows

library(cjoint)
data(immigrationconjoint)

# Clean column names (remove spaces)
names(immigrationconjoint) <- gsub(" ", "", names(immigrationconjoint))

immig <- as.data.frame(immigrationconjoint)

# Strip haven labels, convert to plain factors
for (col in names(immig)) {
  if (is.factor(immig[[col]])) {
    immig[[col]] <- factor(as.character(immig[[col]]))
  }
}
rownames(immig) <- NULL

save(immig, file = "data/immig.rda", compress = "xz")
cat("Saved immig dataset:", nrow(immig), "rows,",
    length(unique(immig$CaseID)), "respondents,",
    file.size("data/immig.rda"), "bytes\n")
