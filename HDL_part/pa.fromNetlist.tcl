
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name MIPS_TEACH -dir "E:/MIPS_TEACH/planAhead_run_3" -part xc7z020clg484-1
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "E:/MIPS_TEACH/MIPS_PIPE.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {E:/MIPS_TEACH} {ipcore_dir} }
add_files [list {ipcore_dir/data_mem.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/instruction_memory.ncf}] -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_property target_constrs_file "MIPS_PIPE.ucf" [current_fileset -constrset]
add_files [list {MIPS_PIPE.ucf}] -fileset [get_property constrset [current_run]]
link_design
