# GBD 2021：高低温归因的 1 型糖尿病疾病负担分析（部分公开代码）

本仓库提供与研究方法学相关的 **部分 R 代码**，覆盖 1990—2021 年全球疾病负担（GBD 2021）数据的描述性分析、EAPC 趋势分析、Das Gupta 三因素分解、部分图形绘制，以及到 2045 年的 Nordpred 模型点预测。研究指标包括死亡、DALYs 和 YLLs，风险因素为高温与低温。

**注意：** 当前内容是基于已提供的分析脚本和手稿整理的公开示例，而不是完整复现包；没有附带原始 GBD 数据、人口数据、结果文件或手稿，也没有实际使用研究原始数据重新运行模型。温度归因的疾病负担不等于温度对 1 型糖尿病发病的因果影响。

## 文件和方法

| 文件 | 内容 |
|---|---|
| `scripts/01_descriptive.R` | 1990、2021 年的病例负担数量、年龄标化率及原始 GBD 不确定性区间（若有） |
| `scripts/02_eapc.R` | 1990—2021 年 EAPC 及回归模型 95% 置信区间 |
| `scripts/03_decomposition.R` | 按六种替换顺序平均的人口增长／年龄结构／流行病学变化三因素分解 |
| `scripts/04_nordpred.R` | 调用公开 `easyGBDR` 包进行 Nordpred 点预测，至 2045 年 |
| `scripts/05_figures.R` | 全球分性别、SDI 分层趋势图 |
| `tests/run_tests.R` | EAPC 和三因素分解的基础单元测试 |

## 使用方法

1. 建议使用 R 4.2 或以上；其中 EAPC、分解分析用基础 R 实现。绘图安装 `ggplot2`，预测模块需另外安装[公开 easyGBDR 项目](https://github.com/m6w9jbcjt2-cell/easyGBDR-)。手稿记载 R 4.1.0，公开包当前环境要求可能有所不同。
2. 从 [GBD Results Tool](https://vizhub.healthdata.org/gbd-results/) 获取 **GBD 2021** 导出文件，分别放在 `data/country/`、`data/region/` 下，支持 CSV / CSV.GZ。
3. 导出文件须包含 `location, sex, age, year, measure, metric, rei, cause, val` 等列，视情况可有 `lower, upper`。也支持原始导出中的 `location_name`、`measure_name` 等列名。请核对研究病因和风险因素文字标签与 `config.example.R` 是否一致。
4. 分解分析还需要 `data/population/population.csv`，列为 `location, sex, year, age, population`，其中 `population` 是真实人数、不是率。不能用已四舍五入的患病负担数量除以率来反推人口。
5. 在仓库根目录依次执行：

```bash
Rscript scripts/00_check_environment.R
Rscript tests/run_tests.R
Rscript scripts/01_descriptive.R
Rscript scripts/02_eapc.R
Rscript scripts/05_figures.R
# 配齐年龄分组人口数据后：
Rscript scripts/03_decomposition.R
# 安装公开 easyGBDR 包后：
Rscript scripts/04_nordpred.R
```

所有结果会写到 `outputs/`；数据、结果及私有配置文件均已在 `.gitignore` 中排除，避免不经意上传 GitHub。需要更改路径或分析组别时，复制 `config.example.R` 为 `config.R` 后编辑即可。

## 与手稿对应的关键约束

- **EAPC：** 以完整的 1990—2021 年全年龄标化率序列拟合 `log(ASR) ~ year`，按 `100 × (exp(β) − 1)` 报告。严格使用未四舍五入的正值，遇到零值、不完整序列或非有限值，标记为不可估计；不添加常数修正。回归 95% CI 与 GBD 95% UI 并不相同。
- **分解分析：** 将每年的归因负担写成总人口 × 各年龄组人口比例 × 年龄特异率之和，人口规模、年龄结构、疾病率三个因素按所有六种排列顺序依次替换后求平均。结果应加总等于整体变化（允许数值精度误差）。
- **Nordpred：** 仅展示点预测，不对原始 GBD 不确定性抽样进行传播，也不展示预测区间。没有将手稿中 1990—2010 训练、2011—2021 验证的独立回测代码放入此次部分公开版本。模型结果需在实际输入数据与软件环境下重新核验。
- **数据与外部依赖：** 公开仓库不含历史研究数据、手稿追踪修订、其他研究项目的脚本，也不包含第三方软件包源代码。

## 发布前

请参阅 `PUBLISHING_CHECKLIST.md`，核对论文版本、数据使用和引用、软件环境、方法与输出，以及开源许可。**目前未自动添加 MIT 等开源许可证**；公开仓库不等于自动授权他人使用或修改代码。

English documentation: [README.md](README.md).
