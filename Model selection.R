n<- read.csv("~/Dropbox/p.fendleri en japon/climate.csv")
l<-as.data.frame(n[rep(seq_len(nrow(n)), each=5),])
dat2016 <- read.csv("~/Dropbox/p.fendleri en japon/dat2016.csv")
x<-data.frame(l,dat2016)
x[is.na(x)] <- 0 
x<-x[,c(-11,-12)]

rmse <- function(pred,act) mean(sqrt( (act - pred)^2))
mae <- function(pred,act)mean(abs(act-pred))
normalize <- function(x) return((x - min(x)) / (max(x) - min(x)))

d <- as.data.frame(lapply(x, normalize))
s<-lapply(d,ts,frequency=60,start=1983)
t<- lapply(s,stl,s.window="periodic")
u<-sapply(t, "[", "time.series")
r<-lapply(u,function(x)x[,"trend"])
a<-as.data.frame(r)
colnames(a)<- names(t)

######################################################

library(neuralnet)
set.seed(7)
ram<-sample(1:2005,2005)
d_r<-a[ram,]
d_t<-d_r[1:1000,]
d_cv<-d_r[1001:1633,]
d_test<-d_r[1634:2040,]
repe<-1

dep_var <- 'flowers'
indep_vars <- colnames(a[,1:8])

b_ma<-integer(repe);b_co=integer(repe);b_er=integer(repe)#estimators
b_mat<-integer(repe);b_cot=integer(repe);b_ert=integer(repe)#estimators

for(j in 1:repe){
  set.seed(8*j)
  nnets <- Reduce(append, lapply(seq_along(indep_vars),
                                 function(num_vars) {
                                   Reduce(append, apply(combn(length(indep_vars), num_vars), 2, function(vars) {
                                     formula_string <- paste(c(dep_var, paste(indep_vars[vars], collapse = "+")), collapse = '~')
                                     structure(list(neuralnet(as.formula(formula_string), data = d_t,hidden = 1)), .Names = formula_string)
                                   }))
                                 }
  ))
  
  #######################################################
  
  na<-names(nnets)
  nn<-sub(dep_var, "", na); nn=sub("~", "", nn)
  nami<-strsplit(nn, "[+]")
  
  h<- rep( list(list()), NROW(na) )
  for(i in 1:NROW(na)) h[i]=nnets[i]
  
  res<- rep( list(list()), NROW(na) ) 
  for(i in 1:NROW(na)) {
    res[i]=compute(h[[i]],d_cv[,unlist(nami[i])])
  }
  
  u=sapply(res, "[", 2)
  
  fo<-as.data.frame(u)
  resu<-data.frame(fo[,seq.int(2,NROW(na)*2,2)])
  
  rest<- rep( list(list()), NROW(na) ) 
  for(i in 1:NROW(na)) {
    rest[i]<-compute(h[[i]],d_t[,unlist(nami[i])])
  }
  
  ut<-sapply(rest, "[", 2)
  
  fot<-as.data.frame(ut)
  resut<-data.frame(fot[,seq.int(2,NROW(na)*2,2)])
  
  #################################################################3
  
  coree<-integer(NROW(na))
  for(i in 1:NROW(na)){
    coree[i]<-  cor(resu[,i],d_cv$flowers)
  }
  
  er<-integer(NROW(na))
  for(i in 1:NROW(na)){
    er[i]<-  rmse(resu[,i],d_cv$flowers)
  }
  
  ma<-integer(NROW(na))
  for(i in 1:NROW(na)){
    ma[i]<-  mae(resu[,i],d_cv$flowers)
  }
  
  b_ma[j]<-na[which.min(ma)]
  b_co[j]<-na[which.max(coree)]
  b_er[j]<-na[which.min(er)]
  
  
}
######################################################################3

#r_100_co<-table(b_co)#flowers~PCPN+Sw_rad+Lw_rad+heat+s_moist+hum
#r_100_er<-table(b_er)
#r_100_ma<-table(b_ma)

#r_500_co<-table(b_co)# flowers~PCPN+Temp+Sw_rad+Lw_rad+heat+s_moist+hum 
#r_500_er<-table(b_er)
#r_500_ma<-table(b_ma)

r_5002_co<-table(b_co)# flowers~PCPN+Temp+Sw_rad+Lw_rad+heat+s_moist+hum 
r_5002_er<-table(b_er)
r_5002_ma<-table(b_ma)

r_5002_cot<-table(b_cot)# flowers~PCPN+Temp+Sw_rad+Lw_rad+heat+s_moist+hum 
r_5002_ert<-table(b_ert)
r_5002_mat<-table(b_mat)
