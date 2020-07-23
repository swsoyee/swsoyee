library(jsonlite)
library(data.table)

psnine_enhance_script_json <- read_json("https://greasyfork.org/zh-CN/scripts/375985-psn%E4%B8%AD%E6%96%87%E7%BD%91%E5%8A%9F%E8%83%BD%E5%A2%9E%E5%BC%BA/stats.json")

psnine_enhance_data <- data.table(do.call("rbind", psnine_enhance_script_json))

data <- list(
    psnine_enhance_install = sum(unlist(psnine_enhance_data$installs))
)

write(toJSON(data), "./public/data.json")
