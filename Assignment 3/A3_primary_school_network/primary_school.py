from Communities import load_network,reading_txt,generate_save_table,generate_stacked_bars

u_comm =load_network(r'Assginment 3\A3_primary_school_network\primaryschool_u.net','unweighted')
w_comm =load_network(r'Assginment 3\A3_primary_school_network\primaryschool_w.net','weighted')
all_comm=reading_txt("Assginment 3\A3_primary_school_network\metadata_primary_school.txt",False)
reduced_comm=reading_txt("Assginment 3\A3_primary_school_network\metadata_primary_school.txt",True)

#Generating and saving tables predicted vs reall communities
tab1=generate_save_table(u_comm,all_comm,"unweighted","unw_all_comm")
tab2=generate_save_table(u_comm,reduced_comm,"unweighted","unw_red_comm")
tab3=generate_save_table(w_comm,all_comm,"weighted","w_all_comm")
tab4=generate_save_table(w_comm,reduced_comm,"weighted","w_red_comm")

#Generate and save stacked bars
generate_stacked_bars(tab1,"Unweighted_all")
generate_stacked_bars(tab2,"Unweighted_reduced")
generate_stacked_bars(tab3,"Weighted_all")
generate_stacked_bars(tab4,"weighted_reduced")
