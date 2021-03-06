library(jsonlite)
library(data.table)
library(rvest)

# 1. ==== Fetch stats of PSNINE enhance script ====
psnine_enhance_script_json <- read_json("https://greasyfork.org/zh-CN/scripts/375985-psn%E4%B8%AD%E6%96%87%E7%BD%91%E5%8A%9F%E8%83%BD%E5%A2%9E%E5%BC%BA/stats.json")

psnine_enhance_data <- data.table(do.call("rbind", psnine_enhance_script_json))

# 2. ==== Fetch stats of covid-2019.live ====
covid_2019_live_url <- "https://cdn.covid-2019.live/static/stats.json"
covid_2019_live <- fromJSON(covid_2019_live_url)

covid_2019_live_stats <- data.table(
  date = as.Date(covid_2019_live$result$timeseries$since),
  pv = covid_2019_live$result$timeseries$pageviews$all,
  uv = covid_2019_live$result$timeseries$uniques$all
)

pv <- sum(covid_2019_live_stats$pv)

# 3. ==== Fetch TCC-GUI paper citations
tcc_gui <- "https://bmcresnotes.biomedcentral.com/articles/10.1186/s13104-019-4179-2/metrics"
tcc_gui_html <- read_html(tcc_gui)
tcc_gui_metrics <- tcc_gui_html %>% html_nodes(".c-article-metrics__access-citation") %>% html_text()

citations <- strsplit(x = gsub(pattern = "  ", replacement = "", x = tcc_gui_metrics), split = "\n")[[3]][2]

# ==== Create JSON ====
data <- list(
  psnine_enhance_install = sum(unlist(psnine_enhance_data$installs)),
  citations = as.numeric(citations),
  covid_2019_live_pv = pv
)

write(toJSON(data), "./public/data.json")
