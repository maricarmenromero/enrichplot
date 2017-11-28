##' gene-concept network
##'
##'
##' @title cnetplot
##' @param x enrichment result. e.g. instance of gseaResult or enrichResult
##' @param showCategory number of enriched terms to display
##' @param foldChange fold Change
##' @param layout layout of the network
##' @param circular whether using circular layout
##' @param ... additional parameters
##' @return ggplot object
##' @importFrom ggraph geom_edge_arc
##' @export
##' @examples
##' library(DOSE)
##' data(geneList)
##' de <- names(geneList)[1:100]
##' x <- enrichDO(de)
##' cnetplot(x)
##' @author guangchuang yu
cnetplot <- function(x,
                     showCategory = 5,
                     foldChange   = NULL,
                     layout = "kk",
                     circular = FALSE,
                     ...) {

    if (circular) {
        layout <- "linear"
        geom_edge <- geom_edge_arc
    } else {
        geom_edge <- geom_edge_link
    }

    n <- update_n(x, showCategory)
    geneSets <- extract_geneSets(x, n)

    g <- list2graph(geneSets)

    foldChange <- fc_readable(x, foldChange)

    size <- sapply(geneSets, length)
    V(g)$size <- min(size)/2
    V(g)$size[1:n] <- size


    if (!is.null(foldChange)) {
        fc <- foldChange[V(g)$name[(n+1):length(V(g))]]
        V(g)$color <- NA
        V(g)$color[(n+1):length(V(g))] <- fc
        palette <- fc_palette(fc)
        p <- ggraph(g, layout=layout, circular = circular) +
            geom_edge(alpha=.8, colour='darkgrey') +
            geom_node_point(aes_(color=~as.numeric(as.character(color)), size=~size)) +
            scale_color_gradientn(name = "fold change", colors=palette, na.value = "#E5C494")
    } else {
        V(g)$color <- "#B3B3B3"
        V(g)$color[1:n] <- "#E5C494"
        p <- ggraph(g, layout=layout, circular=circular) +
            geom_edge(alpha=.8, colour='darkgrey') +
            geom_node_point(aes_(color=~I(color), size=~size))
    }

    p + scale_size(range=c(3, 10), breaks=unique(round(seq(min(size), max(size), length.out=4)))) +
        geom_node_text(aes_(label=~name), repel=TRUE) + theme_void()
}


##' convert a list of gene IDs to igraph object.
##'
##'
##' @title convert gene IDs to igraph object
##' @param inputList a list of gene IDs
##' @return a igraph object.
##' @importFrom igraph graph.data.frame
##' @author Guangchuang Yu
list2graph <- function(inputList) {
    x <- list2df(inputList)
    g <- graph.data.frame(x, directed=FALSE)
    return(g)
}


list2df <- function(inputList) {
    ldf <- lapply(1:length(inputList), function(i) {
        data.frame(categoryID=rep(names(inputList[i]),
                                  length(inputList[[i]])),
                   Gene=inputList[[i]])
    })

    do.call('rbind', ldf)
}

