library(rvest)
library(RSelenium)

rs = RSelenium::rsDriver(browser = "chrome", port=4568L)

rsc = rs$client

rsc$navigate("https://www.youtube.com/playlist?list=PLP8iPy9hna6StY9tIJIUN3F_co9A0zh0H")

ht = rsc$getPageSource()

ok <- xml2::read_html(ht[[1]])

ok %>%
  html_nodes("h3.style-scope.ytd-playlist-video-renderer") %>%
  html_text() -> texts

length(texts)

titles = texts %>%
  strsplit("[|]") %>%
  purrr::map_chr(~ifelse(length(.x) == 1, .x, .x[2]) %>% trimws)


urls = ok %>% 
  html_nodes("a.yt-simple-endpoint.style-scope.ytd-playlist-video-renderer") %>%
  html_attr("href")



# go to the url 
get_views <- function(url) {
  rsc$navigate(paste0("https://www.youtube.com", url))
  Sys.sleep(5)
  while(!rsc$getStatus()$ready) {
    Sys.sleep(10)
  }
  
  ht2 = rsc$getPageSource()
  
  ok2 <- xml2::read_html(ht2[[1]])
  
  ok2 %>% 
    html_nodes("div.style-scope.ytd-menu-renderer a.yt-simple-endpoint.style-scope") %>%
    html_text %>%
    strsplit("\n") %>%
    purrr::map(~.x[1]) %>%
    unlist -> ok3
  
  like_dislike = as.integer(ok3[1:2])
  
  views = ok2 %>%
    html_node("span.view-count.style-scope.yt-view-count-renderer") %>%
    html_text %>%
    strsplit(" ")
  
  views = stringr::str_remove(views[[1]][1], ",") %>% as.integer
  
  list(raw = ok2, data=data.table(views = views, likes = like_dislike[1], disklikes = like_dislike[2]))
}

library(data.table)
pt = proc.time()
the_data = purrr::map(urls, get_views)
print(timetaken(pt))



the_data1 = purrr::map_dfr(the_data, ~.x[[2]])
setDT(the_data1)
the_data1[,titles := titles]
the_data1[,url := paste0("https://youtube.com", urls)]

fwrite(the_data1, "juliacon_19.csv")



# library(purrr)
# 
# 
# 
# pt = proc.time()
# the_data_raw_failed = purrr::map(urls[map(the_data1, ~which(is.na(.x)))[[1]]], get_views)
# print(timetaken(pt))
# 
# the_data_raw_failed1 = purrr::map_dfr(the_data_raw_failed, ~.x[[2]])
# the_data_raw_failed1
# 
# failed_id = map(the_data1, ~which(is.na(.x)))[[1]]
# the_data_raw_failed1[,id:=failed_id]
# 
# setDT(the_data1)
# the_data1[,id:=1:.N]
# 
# 
# 
# 
# row(the_data_complete)
# 
# library(data.table)
# pt = proc.time()
# the_data_raw_failed2 = purrr::map(urls[101:111], get_views)
# print(timetaken(pt))
# the_data_raw_failed2a = purrr::map_dfr(the_data_raw_failed2, ~.x[[2]])
# 
# 
# the_data_complete = rbindlist(list(the_data1[-failed_id], the_data_raw_failed1, the_data_raw_failed2a))
