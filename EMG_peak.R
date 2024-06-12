# written by Liangying, 2024/02/26


library(tidyverse)
library(ggplot2)


df = read.csv(file="")

df$EMG_peak = df$EMG_peak * 1000

df_f = df %>% filter(EMG_peak >= 5)


ggplot(df_f, aes(x = Cond, y = EMG_peak, fill = Cue)) +
  geom_violin(position=position_dodge(1)) +
  #geom_point(position = position_jitter(width = 0.1), alpha = 0.5) +
  geom_dotplot(binaxis='y', stackdir='center',
               position=position_dodge(1), dotsize = 1)+
  labs(x = "Condition", y = "EMG peak", fill = "Cue") +
  theme_bw()+
  theme(legend.text = element_text(size = 10),
        legend.title = element_text(size = 11,face = "bold"),
        axis.title.x = element_text(size = 12, face = "bold", margin = margin(t = 7)),
        axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)),
        axis.text.x = element_text(size = 13, face = "bold", vjust = 0.5, hjust = 0.5),
        axis.text.y = element_text(size = 13,face = "bold"))



#------------------------------ALL subs data--------------------------------------

df_all = read.csv(file = "")
df_all$EMG_filt_bc_peak = df_all$EMG_filt_bc_peak * 1000

df_all_hab = df_all %>% group_by(id, visit) %>%  slice(1:24)
df_all_task = df_all %>% group_by(id, visit) %>%  slice(-(1:24))

df_all_hab = df_all_hab %>% group_by(id, visit) %>% mutate(cond2 = c(rep('pre', 12), rep('post', 12)))
df_all_hab$cond2 <- factor(df_all_hab$cond2, levels = c("pre", "post"))

df_all_hab = df_all_hab %>% group_by(id, visit) %>% mutate(t = c(rep(seq(1, length.out = 12, by = 10), 2)))



ggplot(df_all_hab, aes(x = t, y = EMG_filt_bc_peak)) +
  geom_line(aes(color = cond2), size = 1) +
  scale_color_manual(labels = c("pre","post"), values = c("#fcd000","#00a78e"))+
  facet_wrap(~ id + visit, scale = "fixed")+
  labs(x = "time(s)", y = "EMG peak (μV)", color = "LIFU/Sham")+
  scale_x_continuous(breaks = c(1,21,41,61,81,101), labels = c(1,21,41,61,81,101))+
  theme_bw()+
  theme(
       legend.text = element_text(size = 12),
       legend.title = element_text(size = 12,face = "bold"),
     
        axis.text.x = element_text(size = 13, face = "bold", vjust = 1, hjust = 1, angle = 45),
        axis.text.y = element_text(size = 13,face = "bold"),
        axis.title.x = element_text(size = 15, face = "bold",
                                    margin = margin(t = 10, r = 0, b = 0, l = 0)), # change the distance between the axis title and the numbers.
        axis.title.y = element_text(size = 15, face = "bold",
                                    margin = margin(t = 0, r = 10, b = 0, l = 0)), # change the distance between the axis title and the numbers.
        axis.ticks.length.y = unit(0.15, 'cm'),
        plot.title = element_text(size = 15, face = "bold", hjust = 0.5, vjust = 4),
        plot.margin = margin(t = 20))

#install.packages("ggpubr")
library(ggpubr)

df_all_task$Cond = factor(df_all_task$Cond, levels = c("N", "P", "U"))
df_all_task$Cue = factor(df_all_task$Cue, levels = c("noCue", "Cue"))
df_all_task_f = df_all_task %>% filter(Cond != "H")

ggviolin(df_all_task_f, x = "Cond", y = "EMG_filt_bc_peak", 
         color = "Cue",
         #palette = c("#B3CDE3", "#DECBE4"),
         palette = c("#B3CDE3", "#DECBE4"),
         add = c("boxplot", "jitter"),
         add.params = list(color = "Cue"),
         legend = "right"
         )+
  labs(y = "EMG peak (μV)")+
  facet_wrap(~ id + visit, scale = "free")+
  theme_bw()+
  theme(
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 12,face = "bold"),
    
    axis.text.x = element_text(size = 13, face = "bold", vjust = 0, hjust = 0),
    axis.text.y = element_text(size = 13,face = "bold"),
    axis.title.x = element_text(size = 15, face = "bold",
                                margin = margin(t = 10, r = 0, b = 0, l = 0)), # change the distance between the axis title and the numbers.
    axis.title.y = element_text(size = 15, face = "bold",
                                margin = margin(t = 0, r = 10, b = 0, l = 0)), # change the distance between the axis title and the numbers.
    axis.ticks.length.y = unit(0.15, 'cm'),
    plot.title = element_text(size = 15, face = "bold", hjust = 0.5, vjust = 4),
    plot.margin = margin(t = 20))


