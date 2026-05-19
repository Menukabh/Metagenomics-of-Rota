# List the files
files <- list.files("../results/MAGS_counts/", pattern="*.txt", full.names=TRUE)
files

## Apply a function to every element and 
dfs <- lapply(files, function(f) {
  read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
})

# Take a list and merge them by step by step
merged <- Reduce(function(x, y) merge(x, y, by = 1, all = TRUE), dfs)
merged_data<- as.data.frame(merged)

# Save the results
write_xlsx(merged_data, "../results/MAGS_counts/MAGS_counts.xlsx")
