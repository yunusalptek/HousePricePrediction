library(data.table)

house_dt<-fread("./project/volume/data/raw/Stat_380_housedata.csv")
qc_data<-fread("./project/volume/data/raw/Stat_380_QC_table.csv")
ex_sub<-fread("./project/volume/data/raw/example_sub.csv")

setkey(house_dt, qc_code)
setkey(qc_data, qc_code)
house_dt<-merge(house_dt, qc_data, all.x=T)

# sep into train and test 

train<-house_dt[grep("train_",house_dt$Id)]

test<-house_dt[grep("test_",house_dt$Id)]

# put rows in order
test$sort_col<-gsub("test_","",test$Id)
test$sort_col<-as.integer(test$sort_col)
ordered_test<-test[order(sort_col)]

# group the train by something, get avg saleprice in group

avg_price_by_group<-train[,.(Avg_SalePrice = mean(SalePrice, na.rm = T)), by=.(Cond, Qual)]

#merge the avg table to the test table

setkey(ordered_test, Cond, Qual)
setkey(avg_price_by_group, Cond, Qual)
merged_test<-merge(ordered_test, avg_price_by_group, all.x=T)

# sort rows again
merged_test$sort_col<-gsub("test_","",merged_test$Id)
merged_test$sort_col<-as.integer(merged_test$sort_col)
merged_ordered_test<-merged_test[order(sort_col)]

#update column names
setnames(merged_ordered_test, "SalePrice", "OldSalePrice")
setnames(merged_ordered_test, "Avg_SalePrice", "SalePrice")

#test$SalePrice<-1000000

#select Id and sale price columns from test
submit<-merged_ordered_test[,.(Id,SalePrice)]
submit[is.na(submit$SalePrice)]
# replace NA values with global average
submit[, SalePrice := fcoalesce(SalePrice, 172150.5)]

#write out test table to process folder as .csv
fwrite(submit,"./project/volume/data/processed/submit.csv")
