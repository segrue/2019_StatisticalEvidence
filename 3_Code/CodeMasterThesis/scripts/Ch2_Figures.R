### import packages ------------------------------------------------------------

# for plotting
require("ggplot2") # http://www.sthda.com/english/wiki/ggplot2-essentials
# http://r-statistics.co/ggplot2-Tutorial-With-R.html
# require("gridExtra")
# require("grid")
require("ggpubr")
require("extrafont") # https://cran.r-project.org/web/packages/extrafont/README.html
# I used the Palatino font for the graphic - you probably need to install it if you're using Linux
# font_import("~/.local/share/fonts") # only run the first time / when new fonts were installed
# loadfonts() # only run the first time / when new fonts were installed

# for data handling
require("data.table")
# require("reshape2") #https://stackoverflow.com/questions/21563864/ggplot2-overlay-density-plots-r

# custom functions
source("./functions/helper_functions.R")

### define input paths (for data) and outpout paths (for figures)---------------
in_path <- "data/"
out_path <- "figs/chapter2/"

### properties that should be the same across all figures ---------------
font_size <- 16
font_family <- "Palatino Linotype"
A4 <- c(8.27, 11.69) # width and height of A4 page in inches
A5 <- c(5.8, 8.3) # width and height of an A5 page

### Figure 2.1: Type I and Type II error explained (fig:error_types)
figname <- "ch2_fig1_error_types"
x_max <- 5
mu0 <- 0
mu1 <- 2
p_alpha <- 0.05

# define x and y ranges
x <- seq(-x_max, x_max, by = 0.001)
x_major_breaks <- c(seq(-x_max + 1, x_max - 1, by = 2))
x_minor_breaks <- c(x_major_breaks - 1)[-1]
y_major_breaks <- seq(0, 1, by = 0.25)

q_alpha <- qnorm(p_alpha, mu0, 1, lower.tail = FALSE)
p_beta <- pnorm(q_alpha, mean = mu1, 1)

# plot density function

p1 <- ggplot(data = data.table(x), aes(x = x)) +
  stat_function(fun = dnorm, args = list(mean = mu0), aes(linetype = "1")) +
  stat_function(
    fun = dnorm, xlim = c(q_alpha, x_max), geom = "area",
    args = list(mean = mu0), alpha = 0.5, aes(fill = "1")
  ) +
  stat_function(fun = dnorm, args = list(mean = mu1), aes(linetype = "2")) +
  stat_function(
    fun = dnorm, xlim = c(-x_max, q_alpha), geom = "area",
    args = list(mean = mu1), alpha = 0.5, aes(fill = "2")
  ) +
  scale_linetype(
    name = "Mean:",
    labels = c(bquote(mu == .(mu0)), bquote(mu == .(mu1)))
  ) +
  scale_fill_manual(
    name = "Error:",
    labels = c(
      bquote(alpha == .(p_alpha)),
      bquote(beta == .(round(p_beta, 2)))
    ),
    values = c("1" = alpha("red", 0.5), "2" = alpha("blue", 0.5))
  ) +
  scale_x_continuous(
    breaks = c(x_major_breaks, q_alpha),
    labels = c(x_major_breaks, bquote(z[(1 - alpha)])),
    minor_breaks = x_minor_breaks
  ) +
  theme(
    panel.grid.major.x = element_line(color = c(rep("white", length(x_major_breaks)), NA)),
    panel.grid.minor.y = element_blank(),
    text = element_text(size = text_size, family = font_family)
  ) +
  ylab(label = bquote(phi(x - mu))) #+
# theme(axis.title.x = element_blank(), axis.text.x = element_blank())
# leg <- get_legend(p1)

# plot cdf
p2 <- ggplot(data = data.table(x), aes(x = x)) +
  stat_function(fun = pnorm, args = list(mean = mu0), aes(linetype = "1")) +
  stat_function(fun = pnorm, args = list(mean = mu1), aes(linetype = "2")) +
  geom_segment(aes(x = -x_max, y = 1 - p_alpha, xend = q_alpha, yend = 1 - p_alpha),
    col = "red", size = 0.3
  ) +
  geom_segment(aes(x = q_alpha, y = 1 - p_alpha, xend = q_alpha, yend = 1),
    col = "red", size = 0.3
  ) +
  geom_segment(aes(x = -x_max, y = p_beta, xend = q_alpha, yend = p_beta),
    col = "blue", size = 0.3
  ) +
  geom_segment(aes(x = q_alpha, y = 0, xend = q_alpha, yend = p_beta),
    col = "blue", size = 0.3
  ) +
  scale_x_continuous(
    breaks = c(x_major_breaks, q_alpha),
    labels = c(x_major_breaks, bquote(z[(1 - alpha)])),
    minor_breaks = x_minor_breaks
  ) +
  theme(
    panel.grid.major.x = element_line(color = c(rep("white", length(x_major_breaks)), NA)),
    panel.grid.minor.y = element_blank(),
    text = element_text(size = font_size, family = font_family)
  ) +
  ylab(label = bquote(Phi(x - mu)))

# plot figure
# make sure that all axis are nicely aligned:
# http://www.sthda.com/english/wiki/print.php?id=177
fig1 <- ggarrange(p1, p2 + theme(legend.position = "none"),
  ncol = 1, nrow = 2,
  align = "hv", legend = "top", common.legend = T, labels = c("A", "B")
)
ggsave(
  filename = paste0(out_path, figname, ".pdf"), plot = fig1,
  width = A5[2], height = A5[1], device = cairo_pdf
)


### Figure 2.2: Normal fit of Zn & Vn based on binomial ------------------------
### (fig:normal_fit_binomial_[Corr])
corr <- "MLE" # either "MLE" for no correction or "Ans" vor Anscombe correction

# define figure name
figname <- paste0("ch2_fig2_normal_fit_binomial_", corr)

# load data
load(paste0(in_path, "binom_quantiles_", corr, "_5000_20190505.RData"),
  verbose = TRUE
)
# variables are
# cdf: cumulative probability
# p0: p under H0
# p1: p under H1
# quantile: x-value corresponding to cumulative probability prob
# id: th = cdf of the normal distribution with mu = ; Zn = cdf of z-score based on binomial
#     Vn = cdf of variance stabilised evidence measure Vn
# n_study: number of samples per simulated study

# plotting multiple plots in one window: https://cran.r-project.org/web/packages/egg/vignettes/Ecosystem.html
# n=5

cdf_plotter <- function(dat) {
  q_min <- min(dat[id == "th", ]$quantile)
  q_max <- max(dat[id == "th", ]$quantile)
  cdf_plot <- ggplot(data = dat, aes(
    x = quantile, y = cdf, col = id,
    group = interaction(p1, id), linetype = factor(p1)
  )) +
    geom_line() + scale_color_manual(
      name = "F(x):",
      labels = c(
        bquote(Phi(x - E * "[" * Z[n] * "]")), bquote(Z[n]),
        bquote(V[n] - E * "[" * V[n] * "]" + E * "[" * Z[n] * "]")
      ),
      values = c("th" = "green", "Zn" = "blue", "Vn" = "red")
    ) +
    scale_linetype_manual(
      name = bquote(H[1] ~ ":"),
      labels = c(
        bquote(p == 0.1), bquote(p == 0.5),
        bquote(p == 0.9)
      ),
      values = c("solid", "dashed", "dotdash")
    ) +
    ylim(0, 1) + ggtitle(bquote("n" == .(dat$n_study[1]))) +
    labs(x = "x", y = "F(x)") + coord_cartesian(xlim = c(q_min, q_max)) +
    theme(
      text = element_text(size = font_size, family = font_family),
      plot.title = element_text(size = font_size)
    )
}

qq_plotter <- function(dat) {
  q_min <- min(dat[id == "th", ]$quantile)
  q_max <- max(dat[id == "th", ]$quantile)
  th_quantiles <- qnorm(seq(0.01, 0.99,
    along.with = dat[id == "th" & p1 == 0.1, quantile]
  ), 0, 1)
  dat$q_theoretical <- rep(th_quantiles, dim(unique(dat[, .(id, p1)]))[1])
  q_plot <- ggplot(data = dat, aes(
    x = q_theoretical, y = quantile, col = id,
    group = interaction(p1, id), linetype = factor(p1)
  )) +
    geom_line() + scale_color_manual(values = c("th" = "green", "Zn" = "blue", "Vn" = "red")) +
    scale_linetype_manual(values = c("solid", "dashed", "dotdash")) +
    labs(x = bquote(Phi^{
      -1
    } * (x)), y = bquote(F^{
      -1
    } * (x))) +
    coord_cartesian(ylim = c(q_min, q_max)) +
    theme(
      text = element_text(size = font_size, family = font_family),
      legend.position = "none"
    )
}

# plot all figures (two for each n_study) on the same page
p1 <- cdf_plotter(quantiles[quantiles$n_study == 5, ])
p2 <- qq_plotter(quantiles[quantiles$n_study == 5, ])
p3 <- cdf_plotter(quantiles[quantiles$n_study == 10, ])
p4 <- qq_plotter(quantiles[quantiles$n_study == 10, ])
p5 <- cdf_plotter(quantiles[quantiles$n_study == 20, ])
p6 <- qq_plotter(quantiles[quantiles$n_study == 20, ])
# p7 <- cdf_plotter(quantiles[quantiles$n_study==30,])
# p8 <- qq_plotter(quantiles[quantiles$n_study==30,])
fig2 <- ggarrange(p1, p2, p3, p4, p5, p6,
  ncol = 2, nrow = 3,
  align = "hv", legend = "top", common.legend = T,
  labels = c("A", "", "B", "", "C", "")
)
ggsave(
  filename = paste0(out_path, figname, ".pdf"), plot = fig2,
  width = A4[1], height = 0.9 * A4[2], device = cairo_pdf
)


### Figure 2.3: Plot Zn & Vn against p1 ----------------------------------------
### (fig:evidence_binom_[Corr])
corr <- "MLE"

# define figure name
figname <- paste0("ch2_fig3_evidence_binom_", corr)

# load data
load(paste0("data/Ev_Binom_", corr, "_1e+05_20190504.RData"), verbose = TRUE)


# plot fit of empirical distribution of Zn and Vn with theoretical dist
fit_plotter <- function(dat) {
  dat <- dat[id %in% c("Zn", "Vn"), ]
  dat_emp <- dat[th_emp == "emp", ]
  y_min <- min(dat[th_emp == "th", ]$evd_mean / sqrt(dat$n_study[1]), na.rm = T)
  y_max <- max(dat[th_emp == "th", ]$evd_mean / sqrt(dat$n_study[1]), na.rm = T)
  fit_plot <- ggplot(data = dat, aes(
    x = p1, y = evd_mean / sqrt(n_study),
    col = id, group = interaction(factor(p0), th_emp, id),
    linetype = th_emp
  )) +
    geom_line() +
    geom_point(
      data = dat_emp[p1 %in% seq(0.01, 0.99, 0.1), ],
      aes(shape = factor(p0)), alpha = 0.5, size = 1
    ) +
    scale_color_manual(
      name = "Statistic:",
      labels = c("Zn" = bquote(Z[n]), "Vn"= bquote(V[n])),
      values = c("Zn" = "blue", "Vn" = "red")
    ) +
    scale_linetype_manual(
      name = "emp/th:",
      values = c("th" = "dashed", "emp" = "solid")
    ) +
    coord_cartesian(ylim = c(y_min, y_max)) +
    scale_shape_manual(
      name = bquote(H[0] * ":"),
      labels = c("0.1"= bquote(p == 0.1), "0.5" =bquote(p == 0.5), "0.9"= bquote(p == 0.9)),
      values = c("0.1" = 3, "0.5" = 1, "0.9" = 4)
    ) +
    labs(x = bquote(p[1]), y = bquote(tau * "/" * sqrt(n))) +
    ggtitle(bquote("n" == .(dat$n_study[1]))) +
    theme(
      text = element_text(size = font_size, family = font_family),
      plot.title = element_text(size = font_size)
    )

  return(fit_plot)
}

# plot empirical variance around Zn and Vn
sd_plotter <- function(dat) {
  dat <- dat[p0 == 0.5]
  y_min <- min(dat[th_emp == "th", ]$evd_mean / sqrt(dat$n_study[1]), na.rm = T)
  y_max <- max(dat[th_emp == "th", ]$evd_mean / sqrt(dat$n_study[1]), na.rm = T)
  sd_plot <- ggplot(
    data = dat[(id == "Zn" | id == "Vn") & th_emp == "emp" & p0 == 0.5, ],
    aes(
      x = p1, y = evd_mean / sqrt(n_study),
      col = id, group = interaction(factor(p0), th_emp, id),
      linetype = th_emp
    )
  ) +
    geom_line() + geom_ribbon(
      data = dat[(id == "Zn" | id == "Vn") & th_emp == "emp", ],
      aes(
        ymin = (evd_mean - evd_sd) / sqrt(n_study),
        ymax = (evd_mean + evd_sd) / sqrt(n_study), fill = id
      ),
      alpha = 0.5, linetype = "blank"
    ) +
    scale_color_manual(
      name = "Statistic:",
      labels = c("Zn" = bquote(Z[n]), "Vn"= bquote(V[n])),
      values = c("Zn" = "blue", "Vn" = "red"),
      guide = F
    ) +
    scale_fill_manual(
      name = "Statistic:",
      labels = c("Zn" = bquote(Z[n]), "Vn"= bquote(V[n])),
      values = c("Zn" = "blue", "Vn" = "red")
    ) +
    coord_cartesian(ylim = c(y_min, y_max)) +
    labs(x = bquote(p[1]), y = bquote(tau * "/" * sqrt(n))) +
    theme(text = element_text(size = font_size, family = font_family))
  return(sd_plot)
}


p1 <- fit_plotter(evidence_binom[evidence_binom$n_study == 10, ])
p2 <- sd_plotter(evidence_binom[evidence_binom$n_study == 10, ])
p3 <- fit_plotter(evidence_binom[evidence_binom$n_study == 30, ])
p4 <- sd_plotter(evidence_binom[evidence_binom$n_study == 30, ])
p5 <- fit_plotter(evidence_binom[evidence_binom$n_study == 50, ])
p6 <- sd_plotter(evidence_binom[evidence_binom$n_study == 50, ])

fig3 <- ggarrange(p1, p2, p3, p4, p5, p6,
  ncol = 2, nrow = 3,
  align = "hv", legend = "top", common.legend = T,
  labels = c("A", "", "B", "", "C", "")
)
ggsave(
  filename = paste0(out_path, figname, ".pdf"), plot = fig3,
  width = A4[1], height = 0.9 * A4[2], device = cairo_pdf
)

### Figure 2.4: Plot Power of Zn, Vn & Binom -----------------------------------
### (fig:power_binom_[Corr])
corr <- "Ans"

# define figure name
figname <- paste0("ch2_fig4_power_binom_", corr)

# load data
load(paste0("data/Ev_Binom_", corr, "_1e+05_20190504.RData"), verbose = TRUE)

# plot üpwer curves
power_plotter <- function(dat) {
  power_plot <- ggplot(data = dat, aes(
    x = p1,y=power,col=id,group=interaction(p0,th_emp,id),linetype=th_emp)) +
    geom_line(alpha=0.5) + 
    scale_color_manual(
      name = "Statistic:",
      labels = c("Zn" = bquote(Z[n]), "Vn"= bquote(V[n]), "binom" = "Bin"),
      values = c("Zn" = "blue", "Vn" = "red", "binom" = "green")
    ) +
    geom_point(
      data = dat[p1 %in% seq(0.01, 0.99, 0.1), ],
      aes(shape = factor(p0)), alpha = 0.5, size = 1
    ) +
    scale_linetype_manual(
      name = "emp/th:",
      values = c("th" = "dashed", "emp" = "solid"), 
      drop = F,
      guide = F
    ) +
    scale_shape_manual(
      name = bquote(H[0] * ":"),
      labels = c("0.1"= bquote(p == 0.1), "0.5" =bquote(p == 0.5), "0.9"= bquote(p == 0.9)),
      values = c("0.1" = 3, "0.5" = 1, "0.9" = 4)
    ) +
    labs(x = bquote(p[1]), y = bquote("1-"*beta)) +
    theme(
      text = element_text(size = font_size, family = font_family),
      plot.title = element_text(size = font_size)
    ) + 
    geom_segment(aes(x = 0, y = 0.05, xend = 1, yend = 0.05),
                       col = "black", size = 0.3, linetype = "dotted"
    ) +
    geom_segment(aes(x = 0.1, y = 0, xend = 0.1, yend = 1),
                 col = "black", size = 0.3, linetype = "dotted"
    ) +
    geom_segment(aes(x = 0.9, y = 0, xend = 0.9, yend = 1),
                 col = "black", size = 0.3, linetype = "dotted"
    ) +
    geom_segment(aes(x = 0.5, y = 0, xend = 0.5, yend = 1),
                 col = "black", size = 0.3, linetype = "dotted"
    ) 
  return(power_plot)
}

# p0 <- power_plotter(evidence_binom[n_study==5 & th_emp=="emp",])
p1 <- power_plotter(evidence_binom[n_study==10 & th_emp=="emp",])
p2 <- power_plotter(evidence_binom[n_study==30 & th_emp == "emp",])
p3 <- power_plotter(evidence_binom[n_study==50 & th_emp == "emp",])
#p4 <- power_plotter(evidence_binom[n_study==100 & th_emp == "emp",])

fig4 <- ggarrange(
  # p0 + ggtitle(bquote("n" == 5)),
  # p0 + coord_cartesian(ylim=c(0,0.1)), 
  p1 + ggtitle(bquote("n" == 10)), 
  p1 + coord_cartesian(ylim=c(0,0.1)), 
  p2 + ggtitle(bquote("n" == 30)), 
  p2 +coord_cartesian(ylim=c(0,0.1)),
  p3 + ggtitle(bquote("n" == 50)), 
  p3 + coord_cartesian(ylim=c(0,0.1)),
  # p4 + ggtitle(bquote("n" == 100)), 
  # p4 + coord_cartesian(ylim=c(0,0.1)), 
  ncol = 2, nrow = 3,
  align = "hv", legend = "top", common.legend = T,
  labels = c("A", "", "B","", "C","")
  )

ggsave(
  filename = paste0(out_path, figname, ".pdf"), plot = fig4,
  width = A4[1], height = 0.9 * A4[2], device = cairo_pdf
)


### Figure 2.5: Plot CI of Zn, Vn & Binom -----------------------------------
### (fig:CI_binom_[Corr])

# define figure name
figname <- paste0("ch2_fig5_CI_binom")

# load data
corr <- "MLE"
load(paste0("data/Ev_Binom_", corr, "_1e+05_20190504.RData"), verbose = TRUE)
ev_bin_mle <- evidence_binom

corr <- "Ans"
load(paste0("data/Ev_Binom_", corr, "_1e+05_20190504.RData"), verbose = TRUE)
ev_bin_ans <- evidence_binom

# plot üpwer curves
CI_plotter <- function(dat) {
  dat <- dat[id == "Zn" | id == "Vn"]
  CI_plot <- ggplot(data = dat, aes(
    x = p1,y=CI,col=id,group=interaction(p0,id,th_emp,n_study))) +
    geom_line(alpha=1) +
    scale_color_manual(
      name = "Statistic:",
      labels = c("Zn" = bquote(Z[n]), "Vn"= bquote(V[n])),
      values = c("Zn" = "blue", "Vn" = "red")
    ) +
    scale_shape_manual(
      name = bquote(H[0] * ":"),
      labels = c("0.1"= bquote(p == 0.1), "0.5" =bquote(p == 0.5), "0.9"= bquote(p == 0.9)),
      values = c("0.1" = 3, "0.5" = 1, "0.9" = 4)
    ) +
    # scale_linetype_manual(
    #   name = bquote(H[0] * ":"),
    #   labels = c(bquote(p == 0.1), bquote(p == 0.5), bquote(p == 0.9)),
    #   values = c("0.1" = "solid", "0.5" = "dashed", "0.9" = "dotdash")
    # ) +
    geom_point(
      data = dat[p1 %in% seq(0.01, 0.99, 0.05), ],
      aes(shape = factor(p0)), alpha = 0.5, size = 1
    ) +
    labs(x = bquote(p[1]), y = "CI Coverage") +
    theme(
      text = element_text(size = font_size, family = font_family),
      plot.title = element_text(size = font_size)
    ) + 
    geom_segment(aes(x = 0, y = .95, xend = 1, yend = 0.95),
                 col = "black", size = 0.3, linetype = "dotted"
    ) 
  return(CI_plot)
}

p1 <- CI_plotter(ev_bin_mle[n_study==5 & th_emp=="emp" & p0==0.5,]) + 
      ggtitle(bquote("n" == 5))
p2 <- CI_plotter(ev_bin_ans[n_study==5 & th_emp=="emp" & p0==0.5,])
p3 <- CI_plotter(ev_bin_mle[n_study==10 & th_emp=="emp" & p0==0.5,]) + 
      ggtitle(bquote("n" == 10))
p4 <- CI_plotter(ev_bin_ans[n_study==10 & th_emp=="emp" & p0==0.5,])
p5 <- CI_plotter(ev_bin_mle[n_study==30 & th_emp=="emp" & p0==0.5,]) + 
      ggtitle(bquote("n" == 30))
p6 <- CI_plotter(ev_bin_ans[n_study==30 & th_emp=="emp" & p0==0.5,])
p7 <- CI_plotter(ev_bin_mle[n_study==50 & th_emp=="emp" & p0==0.5,]) + 
      ggtitle(bquote("n" == 50))
p8 <- CI_plotter(ev_bin_ans[n_study==50 & th_emp=="emp" & p0==0.5,])

fig5 <- ggarrange(p1,p2,p3,p4,p5,p6,p7,p8,
  ncol = 2, nrow = 4,
  align = "hv", legend = "top", common.legend = T,
  labels = c("A", "", "B","", "C","","D","")
)

ggsave(
  filename = paste0(out_path, figname, ".pdf"), plot = fig5,
  width = A4[1], height = 0.9 * A4[2], device = cairo_pdf
)