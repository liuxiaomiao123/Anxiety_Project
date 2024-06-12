# written by Liangying, 3/28/2024


library(tidyverse)
library(ggplot2)


df = read.csv(file="")
df2 = df %>% filter(Cond != 'Unpleasant')
# 
# 
# ggplot(df2, aes(x = Cond, y = key2)) +
#   geom_point(aes(color = factor(Cue)), size = 2,position = position_jitterdodge(),alpha = 0.5) +
#  # scale_color_manual(labels = c("pre","post"), values = c("#fcd000","#00a78e"))+
#   facet_wrap(~ id + visit, scale = "fixed")+
#   labs(x = "", y = "Anxiety ratings", color = "Cue")+
#   scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10, by = 2))+
#  # scale_x_continuous(breaks = c(1,21,41,61,81,101), labels = c(1,21,41,61,81,101))+
#   theme_bw()+
#   theme(
#     legend.text = element_text(size = 12),
#     legend.title = element_text(size = 12,face = "bold"),
#     
#     axis.text.x = element_text(size = 13, face = "bold", vjust = 1, hjust = 1, angle = 45),
#     axis.text.y = element_text(size = 13,face = "bold"),
#     axis.title.x = element_text(size = 15, face = "bold"), 
#     axis.title.y = element_text(size = 15, face = "bold",margin = ggplot2::margin(r = 20)),   # the ggplot "margin" function being overridden by a synonymous function from randomForest. 
#     axis.ticks.length.y = unit(0.15, 'cm'),
#     plot.title = element_text(size = 15, face = "bold", hjust = 0.5, vjust = 4),
#     strip.text = element_text(size = 10, face = "bold"))
# 

df2$Cond = factor(df2$Cond, levels = c("N", "P", "U"))
df2$Cue = factor(df2$Cue, levels = c("noCue", "Cue"))

ggviolin(df2, x = "Cond", y = "key2", 
         color = "Cue",
         #palette = c("#B3CDE3", "#DECBE4"),
         #palette = c("#f9eb77", "#04ced1"),
         palette = c("#04ced1","#e38d8c"),
         add = c("boxplot", "jitter"),
         add.params = list(color = "Cue"),
         legend = "right"
)+
  labs(y = "Anxiety ratings")+
  facet_wrap(~ id + visit, scale = "fixed")+
  scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10, by = 2))+
  theme_bw()+
  theme(
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 12,face = "bold"),
    
    axis.text.x = element_text(size = 13, face = "bold", vjust = 0, hjust = 0),
    axis.text.y = element_text(size = 13,face = "bold"),
    axis.title.x = element_text(size = 15, face = "bold",
                                margin = ggplot2::margin(t = 10, r = 0, b = 0, l = 0)), # change the distance between the axis title and the numbers.
    axis.title.y = element_text(size = 15, face = "bold",
                                margin = ggplot2::margin(t = 0, r = 10, b = 0, l = 0)), # change the distance between the axis title and the numbers.
    axis.ticks.length.y = unit(0.15, 'cm'),
    plot.title = element_text(size = 15, face = "bold", hjust = 0.5, vjust = 4),
    plot.margin = ggplot2::margin(t = 20))





