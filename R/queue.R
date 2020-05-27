Queue <- setRefClass(Class = "Queue",
                     fields = list(
                       name = "character",
                       data = "list"
                     ),
                     methods = list(
                       size = function() {
                         'Returns the number of items in the queue.'
                         return(length(data))
                       },
                       #
                       push = function(item) {
                         'Inserts element at back of the queue.'
                         data[[size()+1]] <<- item
                       },
                       #
                       pop = function() {
                         'Removes and returns head of queue (or raises error if queue is empty).'
                         if (size() == 0) stop("queue is empty!")
                         value <- data[[1]]
                         data[[1]] <<- NULL
                         value
                       },
                       #
                       poll = function() {
                         'Removes and returns head of queue (or NULL if queue is empty).'
                         if (size() == 0) return(NULL)
                         else pop()
                       },
                       #
                       peek = function(pos = c(1)) {
                         'Returns (but does not remove) specified positions in queue (or NULL if any one of them is not available).'
                         if (size() < max(pos)) return(NULL)
                         #
                         if (length(pos) == 1) return(data[[pos]])
                         else return(data[pos])
                       },
                       contains = function (item) {
                         return(item %in% data)
                       },
                       clear = function() {
                         'Clears queue.'

                         data <<- list()
                       },
                       initialize=function(...) {
                         callSuper(...)
                         #
                         # Initialise fields here (place holder)...
                         #
                         .self
                       }
                     )
)