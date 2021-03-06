library(mixOmics)
library(scMerge) ## for combing sce's
## load the CellBench data from GitHub
data = "https://github.com/LuyiTian/CellBench_data/blob/master/data/sincell_with_class.RData?raw=true"
load(url(data))
## create a combined sce
sce.list = c("CELseq2" = sce_sc_CELseq2_qc,
             "Dropseq" = sce_sc_Dropseq_qc,
             "10X" = sce_sc_10x_qc)
## merge the sce's into one, keeping common genes and the cell_line colData
sce = scMerge::sce_cbind(sce_list = sce.list, cut_off_batch = 0,
                         cut_off_overall = 0, method = "intersect",
                         batch_names = names(sce.list),
                         colData_names = "cell_line")
## load the wrapper function - change to your rown directory
source("../../wrapper/mixOmics_mint.R")
## check if there are duplicate cell names
sum(duplicated(colnames(sce)))
## ensure there are no duplicate cell names
colnames(sce)  = make.unique(colnames(sce))

## run the wrapper and get both sce and mint.splsda outputs
sce.mint = mixOmics_mint(sce, colData.batch = "batch", colData.class = "cell_line",
                            keepX = c(50,50),  ncomp = 2, output = "both", print.log = FALSE)
## get the mint object
mint = sce.mint$mint
## plot the mint.splsda components for both batches and all cell types
plotIndiv(mint$splsda, title = NULL, subtitle = "MINT sPLSDA",
          legend = TRUE, legend.title = "Cell Line", study = "global")
## plot the mint.splsda components for all cell types for individual batches
plotIndiv(mint$splsda, title = "Individual Studies", subtitle = "MINT sPLSDA",
          legend = TRUE, legend.title = "Cell Line", study = "CELseq2")
## plot the mint.splsda components for all cell types, separated by batches
plotIndiv(mint$splsda, title = "All Studies", 
          legend = TRUE, legend.title = "Cell Line", study = "all.partial")
## takes ~ 90 sec
## run the wrapper and get both tuned sce and mint.splsda outputs - start with a coarse grid
sce.mint.tuned = mixOmics_mint(sce, colData.batch = "batch", colData.class = "cell_line",
                         ncomp = 2, tune.keepX = seq(5,65,20), output = "both")
## get the tuner outputs
tuned_mint = sce.mint.tuned$mint
## plot the error rate over the assessed number of variables
plot(tuned_mint$tune)

## output the optimum number of variables
tuned_mint$tune$choice.keepX
fine.keepX = c(seq(35,47,3), ## for comp 1
               seq(15,27, 3)) ## for comp 2

## run the wrapper with and tune over the fine grid
sce.mint.fine.tuned = mixOmics_mint(sce, colData.batch = "batch", colData.class = "cell_line",
                         ncomp = 2, tune.keepX = fine.keepX, output = "both")
## clustered image map
cim(mint$splsda, comp = c(1,2), margins=c(10,5), 
    row.sideColors = color.mixo(as.numeric(mint$splsda$Y)), row.names = FALSE,
    title = 'MINT sPLS-DA', save = "png", name.save = "heatmap")
knitr::include_graphics("heatmap.png")
## loadings for each signature genes in each study
plotLoadings(mint$splsda, contrib='max', method = 'mean', comp=2, 
             study='all.partial', legend=FALSE, title=NULL, 
             subtitle = unique(mint$splsda$study) )
## correlation circle plot
plotVar(mint$splsda, cex = 3)
## roc curves for each batch
auroc(mint$splsda, roc.comp = 1, roc.study='CELseq2')
## visualise the global components from sce object
df.global = as.data.frame(reducedDim(sce.mint$sce,"mint_comps_global"))
ggplot(df.global, aes(x=df.global[,1], y=df.global[,2],
                      col = colData(sce.mint$sce)[["cell_line"]])) + geom_point() +
  labs(x = "Component 1", y = "Component 2",title = "MINT components for all cells") + guides(col=guide_legend(title="Cell Line"))
## visualise each batch's components from sce object

## see all available reducedDims
reducedDims(sce.mint$sce)
## we will choose the mint_comps_Dropseq
df.dropseq = as.data.frame(reducedDim(sce.mint$sce,"mint_comps_Dropseq"))
## their respective cell lines
ggplot(df.dropseq, aes(x=df.dropseq[,1], y=df.dropseq[,2],
                      col = colData(sce.mint$sce)[["cell_line"]])) + geom_point(na.rm = TRUE) +
  labs(x = "Component 1", y = "Component 2", title = "MINT components for Drop-seq cells") + guides(col=guide_legend(title="Cell Line"))
## look at marker genes
rownames(sce.mint$sce)[rowData(sce.mint$sce)[["mint_marker"]]]
