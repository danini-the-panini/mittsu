module Mittsu
  module Cache
    @@files = {}

    def self.add(key, file)
      @@files[key] = file
    end

    def self.get(key)
      @@files[key]
    end

    def self.remove(key)
      @@files.delete(key)
    end

    def self.clear
      @@files.clear
    end
  end
end

# 	files: {},
#
# 	add: function ( key, file ) {
#
# 		// console.log( 'THREE.Cache', 'Adding key:', key );
#
# 		this.files[ key ] = file;
#
# 	},
#
# 	get: function ( key ) {
#
# 		// console.log( 'THREE.Cache', 'Checking key:', key );
#
# 		return this.files[ key ];
#
# 	},
#
# 	remove: function ( key ) {
#
# 		delete this.files[ key ];
#
# 	},
#
# 	clear: function () {
#
# 		this.files = {}
#
# 	}
#
# };
