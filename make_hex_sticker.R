# ============================================================
# cjdiag Hex Sticker
# ============================================================

library(ggplot2)
library(hexSticker)

# ---- Schematic tree: 90° angles ----
# Left → leaf(0), Right splits → leaf(0) + leaf(1)

nodes <- data.frame(
  x = c(0,    -1.3,  1.3,   0.5,  2.1),
  y = c(3,     1.5,  1.5,   0,    0),
  label = c("", "0", "", "0", "1"),
  is_leaf = c(FALSE, TRUE, FALSE, TRUE, TRUE)
)

# 90° edges
seg <- data.frame(
  x    = c(0,    -1.3,  0,    1.3,  1.3,  0.5,  1.3,  2.1),
  xend = c(-1.3, -1.3,  1.3,  1.3,  0.5,  0.5,  2.1,  2.1),
  y    = c(3,     3,    3,    3,    1.5,  1.5,  1.5,  1.5),
  yend = c(3,     1.5,  3,    1.5,  1.5,  0,    1.5,  0)
)

# Red cross — symmetric, centered at subplot midpoint
# Center of coord_fixed xlim/ylim = (-2.6+3.4)/2, (-1.0+4.0)/2
cx <- 0.4; cy <- 1.5
arm_len <- 2.5   # half-length of each arm
arm_w   <- 0.7   # half-width of each arm
cross <- data.frame(
  # vertical bar, horizontal bar
  xmin = c(cx - arm_w,   cx - arm_len),
  xmax = c(cx + arm_w,   cx + arm_len),
  ymin = c(cy - arm_len, cy - arm_w),
  ymax = c(cy + arm_len, cy + arm_w)
)

p <- ggplot() +
  # Red cross FIRST (background)
  geom_rect(data = cross,
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = "#E74C3C", alpha = 1, color = NA) +
  # Tree edges — thinner, on top of cross
  geom_segment(data = seg,
               aes(x = x, y = y, xend = xend, yend = yend),
               color = "#2C3E50", linewidth = 1.3, lineend = "square") +
  # Leaf nodes
  geom_point(data = nodes[nodes$is_leaf, ],
             aes(x = x, y = y), shape = 22,
             color = "#2C3E50", fill = "#AED6F1", size = 8, stroke = 1) +
  geom_text(data = nodes[nodes$is_leaf, ],
            aes(x = x, y = y, label = label),
            color = "#2C3E50", size = 4, fontface = "bold") +
  # Inner nodes
  geom_point(data = nodes[!nodes$is_leaf, ],
             aes(x = x, y = y),
             color = "#2C3E50", fill = "white", size = 4, shape = 21, stroke = 1) +
  coord_cartesian(xlim = c(-2.6, 3.4), ylim = c(-1.0, 4.0)) +
  theme_void() +
  theme_transparent()

# ---- Sticker ----
out_dir <- "man/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

sticker(
  subplot = p,
  package = "cjdiag",

  p_x = 1, p_y = 1.48,
  p_size = 7,
  p_color = "#2C3E50",
  p_fontface = "bold",

  s_x = 1, s_y = 0.72,
  s_width = 1.3, s_height = 1.0,

  h_fill = "#FFFFFF",
  h_color = "#27AE60",
  h_size = 2.0,

  spotlight = FALSE,

  url = "cjdiag",
  u_size = 1.2,
  u_color = "#27AE60",
  u_x = 1, u_y = 0.08,

  filename = file.path(out_dir, "logo.png"),
  dpi = 300
)

cat("Saved to", file.path(out_dir, "logo.png"), "\n")
