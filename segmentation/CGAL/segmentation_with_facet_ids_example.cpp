/*
 * By Paulo Abelha
 * modified from: http://doc.cgal.org/latest/Surface_mesh_segmentation/index.html
*/

#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/boost/graph/graph_traits_Polyhedron_3.h>
#include <CGAL/Polyhedron_items_with_id_3.h>
#include <CGAL/IO/Polyhedron_iostream.h>
#include <CGAL/mesh_segmentation.h>

#include <CGAL/Simple_cartesian.h>
#include <CGAL/Polyhedron_3.h>	

#include <CGAL/property_map.h>

#include <iostream>
#include <fstream>

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
typedef CGAL::Polyhedron_3<K, CGAL::Polyhedron_items_with_id_3>  Polyhedron;

typedef K::Point_3                              		Point_3;
typedef Polyhedron::Facet_iterator                   	Facet_iterator;
typedef Polyhedron::Halfedge_around_facet_circulator 	Halfedge_facet_circulator;

// Property map associating a facet with an integer as id to an
// element in a vector stored internally
template<class ValueType>
struct Facet_with_id_pmap
    : public boost::put_get_helper<ValueType&,
             Facet_with_id_pmap<ValueType> >
{
    typedef Polyhedron::Facet_const_handle key_type;
    typedef ValueType value_type;
    typedef value_type& reference;
    typedef boost::lvalue_property_map_tag category;

    Facet_with_id_pmap(
      std::vector<ValueType>& internal_vector
    ) : internal_vector(internal_vector) { }

    reference operator[](key_type key) const
    { return internal_vector[key->id()]; }
private:
    std::vector<ValueType>& internal_vector;
};

bool VERBOSE = false;

int main(int argc, char *argv[])
{
    if (VERBOSE) std::cout << "Reading point cloud file: " << argv[1] << std::endl;
	// create and read Polyhedron
	Polyhedron mesh;

	std::ifstream input(argv[1]);
	if ( !input ) {
		std::cerr << "Could not read stream from file" << std::endl;
		return EXIT_FAILURE;
	}
	if ( !(input >> mesh)) {
		std::cerr << "The .off file is invalid" << std::endl;
		return EXIT_FAILURE;
	}
	if ( mesh.empty() ) {
		std::cerr << "Created mesh is empty" << std::endl;
		return EXIT_FAILURE;
	}

    // assign id field for each facet
    std::size_t facet_id = 0;
    for(Polyhedron::Facet_iterator facet_it = mesh.facets_begin();
      facet_it != mesh.facets_end(); ++facet_it, ++facet_id) {
        facet_it->id() = facet_id;
    }

    // create a property-map for SDF values
    std::vector<double> sdf_values(mesh.size_of_facets());
    Facet_with_id_pmap<double> sdf_property_map(sdf_values);

    CGAL::sdf_values(mesh, sdf_property_map);

    // access SDF values (with constant-complexity)
    /*
    for(Polyhedron::Facet_const_iterator facet_it = mesh.facets_begin();
      facet_it != mesh.facets_end(); ++facet_it) {
        std::cout << sdf_property_map[facet_it] << " ";
    }
    std::cout << std::endl;*/
    
    // create a property-map for segment-ids
    // so wee can access segment-ids (with constant-complexity)
    std::vector<std::size_t> segment_ids(mesh.size_of_facets());
    Facet_with_id_pmap<std::size_t> segment_property_map(segment_ids);

    CGAL::segmentation_from_sdf_values(mesh, sdf_property_map, segment_property_map);
    
    // get colormap (still testing - make it generic)
    std::vector<std::string> colormap;
    colormap.push_back("255 0 0");
    colormap.push_back("0 255 0");
    colormap.push_back("0 0 255");     
    colormap.push_back("255 0 0");
    colormap.push_back("0 255 0");
    colormap.push_back("0 0 255");
    colormap.push_back("255 0 0");
    colormap.push_back("0 255 0");
    colormap.push_back("0 0 255"); 
    colormap.push_back("255 0 0");
    colormap.push_back("0 255 0");
    colormap.push_back("0 0 255"); 
    
    // Write polyhedron in Object File Format (OFF).
    CGAL::set_ascii_mode( std::cout);
    std::cout << "OFF" << std::endl << mesh.size_of_vertices() << ' '
              << mesh.size_of_facets() << " 0" << std::endl;
    std::copy( mesh.points_begin(), mesh.points_end(),
               std::ostream_iterator<Point_3>( std::cout, "\n"));
    for (  Facet_iterator i = mesh.facets_begin(); i != mesh.facets_end(); ++i) {
        Halfedge_facet_circulator j = i->facet_begin();
        // Facets in polyhedral surfaces are at least triangles.
        CGAL_assertion( CGAL::circulator_size(j) >= 3);
        std::cout << CGAL::circulator_size(j) << ' ';
        do {
            std::cout << ' ' << std::distance(mesh.vertices_begin(), j->vertex());
        } while ( ++j != i->facet_begin());
        // put color in the face
        std::cout << ' ' << colormap[segment_property_map[i]];
        std::cout << std::endl;
    }
}
